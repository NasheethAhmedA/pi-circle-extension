/**
 * Parallel spawn execution engine for the circle extension.
 *
 * Spawns isolated pi subprocesses for independent read-only tasks.
 * Each subprocess gets the agent's AGENT.md + SKILL.md as system prompt
 * but does NOT see the parent session's conversation history.
 */

import { spawn, type ChildProcess } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { Message } from "@earendil-works/pi-ai";

// ─── Types ───────────────────────────────────────────────────────────────────

export interface SpawnTask {
  agent: string;
  task: string;
  model?: string;
  readOnly?: boolean;
  writePaths?: string[];
}

export interface SpawnResult {
  agent: string;
  task: string;
  status: "success" | "failed" | "timeout" | "aborted";
  output: string;
  error?: string;
  usage: UsageStats;
  model?: string;
  elapsed?: number; // milliseconds
}

interface UsageStats {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  cost: number;
  turns: number;
}

interface RunningTask {
  agent: string;
  task: string;
  proc: ChildProcess;
  result: SpawnResult;
  messages: Message[];
  lastActivity: number;
  startTime: number;
  tmpFile: string;
  tmpDir: string;
}

// ─── Constants ───────────────────────────────────────────────────────────────

// Use exclude-tools to remove write capabilities, keeping everything else (including web_search, web_fetch)
const EXCLUDED_WRITE_TOOLS = "edit,write,bash";
const LAUNCH_STAGGER_MS = 2000;
const IDLE_TIMEOUT_MS = 600_000;   // 10 minutes no output
const HARD_TIMEOUT_MS = 1_800_000; // 30 minutes absolute max
const KILL_GRACE_MS = 5000;        // 5 seconds between SIGTERM and SIGKILL

// ─── Helpers ─────────────────────────────────────────────────────────────────

function getPiInvocation(args: string[]): { command: string; args: string[] } {
  const currentScript = process.argv[1];
  const isBunVirtual = currentScript?.startsWith("/$bunfs/root/");
  if (currentScript && !isBunVirtual && fs.existsSync(currentScript)) {
    return { command: process.execPath, args: [currentScript, ...args] };
  }
  const execName = path.basename(process.execPath).toLowerCase();
  const isGenericRuntime = /^(node|bun)(\.exe)?$/.test(execName);
  if (!isGenericRuntime) {
    return { command: process.execPath, args };
  }
  return { command: "pi", args };
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function getFinalOutput(messages: Message[]): string {
  for (let i = messages.length - 1; i >= 0; i--) {
    const msg = messages[i];
    if (msg.role === "assistant") {
      for (const part of msg.content) {
        if (part.type === "text") return part.text;
      }
    }
  }
  return "";
}

function formatTokens(count: number): string {
  if (count < 1000) return count.toString();
  if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
  return `${Math.round(count / 1000)}k`;
}

export function formatUsageStats(usage: UsageStats, model?: string, elapsed?: number): string {
  const parts: string[] = [];
  if (elapsed) { const secs = (elapsed / 1000).toFixed(1); parts.push(`${secs}s`); }
  if (usage.turns) parts.push(`${usage.turns} turn${usage.turns > 1 ? "s" : ""}`);
  if (usage.input) parts.push(`↑${formatTokens(usage.input)}`);
  if (usage.output) parts.push(`↓${formatTokens(usage.output)}`);
  if (usage.cacheRead) parts.push(`R${formatTokens(usage.cacheRead)}`);
  if (usage.cacheWrite) parts.push(`W${formatTokens(usage.cacheWrite)}`);
  if (usage.cost) parts.push(`$${usage.cost.toFixed(4)}`);
  if (model) parts.push(model);
  return parts.join(" ");
}

// ─── Prompt Building ─────────────────────────────────────────────────────────

export function buildSubagentPrompt(
  agentName: string,
  getAgentMdContent: (name: string) => string | null,
  getGlobalAgentDir: (name: string) => string,
): string {
  // Get AGENT.md
  let prompt = getAgentMdContent(agentName) || "";

  // Get all SKILL.md files from agent's skills directory
  const skillsDir = path.join(getGlobalAgentDir(agentName), "skills");
  if (fs.existsSync(skillsDir)) {
    for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
      if (entry.isDirectory()) {
        const skillMd = path.join(skillsDir, entry.name, "SKILL.md");
        if (fs.existsSync(skillMd)) {
          const content = fs.readFileSync(skillMd, "utf-8");
          prompt += `\n\n---\n[Skill: ${entry.name}]\n${content}`;
        }
      }
    }
  }

  return prompt;
}

async function writePromptToTempFile(agentName: string, prompt: string): Promise<{ dir: string; filePath: string }> {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-spawn-"));
  const safeName = agentName.replace(/[^\w.-]+/g, "_");
  const filePath = path.join(tmpDir, `${safeName}-prompt.md`);
  fs.writeFileSync(filePath, prompt, { encoding: "utf-8", mode: 0o600 });
  return { dir: tmpDir, filePath };
}

// ─── Process Execution ───────────────────────────────────────────────────────

function launchSubprocess(
  task: SpawnTask,
  promptFilePath: string,
  cwd: string,
  defaultModel: string,
): ChildProcess {
  const args: string[] = [
    "--mode", "json",
    "-p",
    "--no-session",
    "--append-system-prompt", promptFilePath,
  ];

  // Read-only: exclude write tools. Write-enabled: no exclusions (full access)
  if (task.readOnly !== false) {
    args.push("--exclude-tools", EXCLUDED_WRITE_TOOLS);
  }

  args.push("--model", task.model || defaultModel);
  args.push(`Task: ${task.task}`);

  const invocation = getPiInvocation(args);
  const proc = spawn(invocation.command, invocation.args, {
    cwd,
    shell: false,
    stdio: ["ignore", "pipe", "pipe"],
  });

  return proc;
}

// ─── Main Execution Function ─────────────────────────────────────────────────

export async function runSpawnTasks(
  tasks: SpawnTask[],
  cwd: string,
  signal: AbortSignal | undefined,
  defaultModel: string,
  getAgentMdContent: (name: string) => string | null,
  getGlobalAgentDir: (name: string) => string,
  onUpdate?: (results: SpawnResult[]) => void,
): Promise<SpawnResult[]> {
  const running: RunningTask[] = [];
  const results: SpawnResult[] = tasks.map(t => ({
    agent: t.agent,
    task: t.task,
    status: "failed" as const,
    output: "(not started)",
    usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 },
    model: t.model || defaultModel,
  }));

  // Abort handler: kill all children
  let aborted = false;
  const abortHandler = () => {
    aborted = true;
    for (const rt of running) {
      if (rt.proc && !rt.proc.killed) {
        rt.proc.kill("SIGTERM");
        setTimeout(() => {
          if (!rt.proc.killed) rt.proc.kill("SIGKILL");
        }, KILL_GRACE_MS);
      }
    }
  };

  if (signal) {
    if (signal.aborted) { abortHandler(); }
    else { signal.addEventListener("abort", abortHandler, { once: true }); }
  }

  const emitUpdate = () => {
    if (onUpdate) onUpdate([...results]);
  };

  // Launch tasks with stagger
  const taskPromises: Promise<void>[] = [];

  for (let i = 0; i < tasks.length; i++) {
    if (aborted) break;
    if (i > 0) await sleep(LAUNCH_STAGGER_MS);
    if (aborted) break;

    const task = tasks[i];
    const idx = i;

    const taskPromise = (async () => {
      const startTime = Date.now();
      // Build prompt and write to temp file
      const prompt = buildSubagentPrompt(task.agent, getAgentMdContent, getGlobalAgentDir);
      const { dir: tmpDir, filePath: tmpFile } = await writePromptToTempFile(task.agent, prompt);

      // Launch subprocess
      const proc = launchSubprocess(task, tmpFile, cwd, defaultModel);
      const rt: RunningTask = {
        agent: task.agent,
        task: task.task,
        proc,
        result: results[idx],
        messages: [],
        lastActivity: Date.now(),
        startTime,
        tmpFile,
        tmpDir,
      };
      results[idx].elapsed = 0;
      running.push(rt);

      // Track stdout (JSON lines)
      let buffer = "";
      proc.stdout!.on("data", (data: Buffer) => {
        rt.lastActivity = Date.now();
        buffer += data.toString();
        const lines = buffer.split("\n");
        buffer = lines.pop() || "";

        for (const line of lines) {
          if (!line.trim()) continue;
          try {
            const event = JSON.parse(line);
            if (event.type === "message_end" && event.message) {
              const msg = event.message as Message;
              rt.messages.push(msg);

              if (msg.role === "assistant") {
                results[idx].usage.turns++;
                const usage = (msg as any).usage;
                if (usage) {
                  results[idx].usage.input += usage.input || 0;
                  results[idx].usage.output += usage.output || 0;
                  results[idx].usage.cacheRead += usage.cacheRead || 0;
                  results[idx].usage.cacheWrite += usage.cacheWrite || 0;
                  results[idx].usage.cost += usage.cost?.total || 0;
                }
                if ((msg as any).model) results[idx].model = (msg as any).model;
              }
              emitUpdate();
            }
          } catch { /* ignore non-JSON lines */ }
        }
      });

      // Track stderr
      let stderr = "";
      proc.stderr!.on("data", (data: Buffer) => {
        rt.lastActivity = Date.now();
        results[idx].elapsed = Date.now() - startTime;
        stderr += data.toString();
        emitUpdate();
      });

      const progressTimer = setInterval(() => {
        results[idx].elapsed = Date.now() - startTime;
        emitUpdate();
      }, 1000);

      // Set up timeouts
      const hardTimer = setTimeout(() => {
        if (!proc.killed) {
          proc.kill("SIGTERM");
          results[idx].status = "timeout";
          results[idx].error = "Hard timeout (30 minutes exceeded)";
        }
      }, HARD_TIMEOUT_MS);

      const idleCheck = setInterval(() => {
        if (Date.now() - rt.lastActivity > IDLE_TIMEOUT_MS && !proc.killed) {
          proc.kill("SIGTERM");
          results[idx].status = "timeout";
          results[idx].error = "Idle timeout (10 minutes no activity)";
        }
      }, 10_000);

      // Wait for process to complete
      const exitCode = await new Promise<number>((resolve) => {
        proc.on("close", (code) => {
          // Process remaining buffer
          if (buffer.trim()) {
            try {
              const event = JSON.parse(buffer);
              if (event.type === "message_end" && event.message) {
                rt.messages.push(event.message as Message);
              }
            } catch { /* ignore */ }
          }
          resolve(code ?? 1);
        });
        proc.on("error", () => resolve(1));
      });

      // Clean up timers
      clearTimeout(hardTimer);
      clearInterval(idleCheck);
      clearInterval(progressTimer);

      // Set result
      const output = getFinalOutput(rt.messages);
      results[idx].elapsed = Date.now() - startTime;

      if (aborted) {
        results[idx].status = "aborted";
        results[idx].output = output || "(aborted)";
        results[idx].error = "Aborted by user";
      } else if (results[idx].status === "timeout") {
        results[idx].output = output || stderr || "(timed out)";
      } else if (exitCode === 0) {
        results[idx].status = "success";
        results[idx].output = output || "(no output)";
      } else {
        results[idx].status = "failed";
        results[idx].output = output || stderr || "(no output)";
        results[idx].error = `Exit code: ${exitCode}`;
      }

      emitUpdate();

      // Cleanup temp files
      try { fs.unlinkSync(tmpFile); } catch { /* ignore */ }
      try { fs.rmdirSync(tmpDir); } catch { /* ignore */ }
    })();

    taskPromises.push(taskPromise);
  }

  // Wait for all tasks to complete
  await Promise.all(taskPromises);

  // Remove abort listener
  if (signal && !signal.aborted) {
    signal.removeEventListener("abort", abortHandler);
  }

  return results;
}
