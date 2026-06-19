/**
 * Circle Extension — Dynamic Context Switching with Modular Agents
 *
 * Agents are global and reusable under the Pi user/project agent roots.
 * Circles reference agents by name under the Pi user/project circle roots.
 * Each circle has its own center agent.
 *
 * Resolution:
 *   Agent context → project override → user override → bundled default
 *   Agent skills  → project override → user override → bundled default
 *   Center agent  → project override → user override → bundled default
 *   Circle skills → project override → user override → bundled default
 *
 * Commands:
 *   /circle        - Activate a circle
 *   /circle-off    - Deactivate current circle
 *   /circle-create - Create a new circle
 *   /circle-list   - List circles
 *   /circle-edit   - Edit a circle
 *   /circle-delete - Delete a circle
 *   /circle-agents - List global agents
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { getAgentDir } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { type SpawnResult, type SpawnTask, buildSubagentPrompt, formatUsageStats, runSpawnTasks } from "./parallel.ts";

// ─── Paths ───────────────────────────────────────────────────────────────────

const PACKAGE_ROOT = path.dirname(fileURLToPath(import.meta.url));

function getUserAgentRoot(): string { return getAgentDir(); }
function getProjectAgentRoot(): string { return path.join(process.cwd(), ".pi", "agent"); }
function getDefaultsRoot(): string { return path.join(PACKAGE_ROOT, "defaults"); }

function getCirclesDir(): string { return path.join(getUserAgentRoot(), "circles"); }
function getGlobalAgentsDir(): string { return path.join(getUserAgentRoot(), "agents"); }
function getProjectCirclesDir(): string { return path.join(getProjectAgentRoot(), "circles"); }
function getProjectGlobalAgentsDir(): string { return path.join(getProjectAgentRoot(), "agents"); }
function getDefaultCirclesDir(): string { return path.join(getDefaultsRoot(), "circles"); }
function getDefaultGlobalAgentsDir(): string { return path.join(getDefaultsRoot(), "agents"); }
function getCircleDir(name: string): string { return path.join(getCirclesDir(), name); }
function getCenterDir(circleName: string): string { return path.join(getCircleDir(circleName), "center"); }
function getGlobalAgentDir(agentName: string): string { return path.join(getGlobalAgentsDir(), agentName); }
function ensureDir(dir: string): void { if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true }); }

function resolveGlobalAgentDir(agentName: string): string | null {
  const candidates = [
    path.join(getProjectGlobalAgentsDir(), agentName),
    path.join(getGlobalAgentsDir(), agentName),
    path.join(getDefaultGlobalAgentsDir(), agentName),
  ];

  for (const dir of candidates) {
    const agentMd = path.join(dir, "AGENT.md");
    const ctxMd = path.join(dir, "context.md");
    if (fs.existsSync(agentMd) || fs.existsSync(ctxMd)) return dir;
  }
  return null;
}

function resolveCircleDir(circleName: string): string | null {
  const candidates = [
    path.join(getProjectCirclesDir(), circleName),
    path.join(getCirclesDir(), circleName),
    path.join(getDefaultCirclesDir(), circleName),
  ];

  for (const dir of candidates) {
    const config = path.join(dir, "circle.json");
    if (fs.existsSync(config)) return dir;
  }
  return null;
}

// ─── Types ───────────────────────────────────────────────────────────────────

interface CircleConfig {
  name: string;
  description: string;
  agents: string[];  // Just names — resolved from global pool
  createdAt: string;
  updatedAt: string;
}

// ─── Storage ─────────────────────────────────────────────────────────────────

function loadCircle(name: string): CircleConfig | null {
  const dir = resolveCircleDir(name);
  if (!dir) return null;
  const p = path.join(dir, "circle.json");
  if (!fs.existsSync(p)) return null;
  try { return JSON.parse(fs.readFileSync(p, "utf-8")); } catch { return null; }
}

function saveCircle(config: CircleConfig): void {
  const dir = getCircleDir(config.name);
  ensureDir(dir);
  ensureDir(getCenterDir(config.name));
  config.updatedAt = new Date().toISOString();
  fs.writeFileSync(path.join(dir, "circle.json"), JSON.stringify(config, null, 2));
  const centerMd = path.join(getCenterDir(config.name), "AGENT.md");
  if (!fs.existsSync(centerMd)) {
    fs.writeFileSync(centerMd, buildCenterContext(config));
  }
}

function deleteCircle(name: string): boolean {
  const dir = getCircleDir(name);
  if (!fs.existsSync(dir)) return false;
  fs.rmSync(dir, { recursive: true, force: true });
  return true;
}

function listCircles(): CircleConfig[] {
  const names = new Set<string>();
  for (const dir of [getDefaultCirclesDir(), getCirclesDir(), getProjectCirclesDir()]) {
    if (!fs.existsSync(dir)) continue;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      if (entry.isDirectory()) names.add(entry.name);
    }
  }

  const circles: CircleConfig[] = [];
  for (const name of names) {
    const config = loadCircle(name);
    if (config) circles.push(config);
  }
  return circles.sort((a, b) => a.name.localeCompare(b.name));
}

function listGlobalAgents(): { name: string; role: string; description: string }[] {
  const names = new Set<string>();
  for (const dir of [getDefaultGlobalAgentsDir(), getGlobalAgentsDir(), getProjectGlobalAgentsDir()]) {
    if (!fs.existsSync(dir)) continue;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      if (entry.isDirectory()) names.add(entry.name);
    }
  }

  const agents: { name: string; role: string; description: string }[] = [];
  for (const name of names) {
    const md = getAgentMdContent(name);
    if (!md) continue;
    const descMatch = md.match(/^---[\s\S]*?description:\s*(.+)/m);
    const roleMatch = md.match(/^#\s+(.+)/m);
    agents.push({
      name,
      role: roleMatch ? roleMatch[1].split("—")[0].trim() : name,
      description: descMatch ? descMatch[1].trim().slice(0, 80) : md.split("\n").find(l => l.trim() && !l.startsWith("#") && !l.startsWith("---"))?.trim().slice(0, 80) || "",
    });
  }
  return agents.sort((a, b) => a.name.localeCompare(b.name));
}

// ─── Agent Context Resolution ────────────────────────────────────────────────

function getAgentMdContent(agentName: string): string | null {
  const agentDir = resolveGlobalAgentDir(agentName);
  if (!agentDir) return null;
  const agentMd = path.join(agentDir, "AGENT.md");
  if (fs.existsSync(agentMd)) return fs.readFileSync(agentMd, "utf-8");
  const ctxMd = path.join(agentDir, "context.md");
  if (fs.existsSync(ctxMd)) return fs.readFileSync(ctxMd, "utf-8");
  return null;
}

function getCenterContext(circleName: string): string {
  const circleDir = resolveCircleDir(circleName);
  if (!circleDir) return "";
  const centerMd = path.join(circleDir, "center", "AGENT.md");
  if (fs.existsSync(centerMd)) return fs.readFileSync(centerMd, "utf-8");
  return "";
}

function getSkills(agentName: string, circleName: string | null, isCenter: boolean): string[] {
  const paths: string[] = [];

  const skillsDir = isCenter && circleName
    ? (() => {
        const circleDir = resolveCircleDir(circleName);
        return circleDir ? path.join(circleDir, "center", "skills") : "";
      })()
    : (() => {
        const agentDir = resolveGlobalAgentDir(agentName);
        return agentDir ? path.join(agentDir, "skills") : "";
      })();

  if (skillsDir && fs.existsSync(skillsDir)) {
    for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
      if (entry.isDirectory()) {
        const sm = path.join(skillsDir, entry.name, "SKILL.md");
        if (fs.existsSync(sm)) paths.push(sm);
      } else if (entry.name.endsWith(".md")) {
        paths.push(path.join(skillsDir, entry.name));
      }
    }
  }

  if (circleName) {
    const circleDir = resolveCircleDir(circleName);
    const circleSkillsDir = circleDir ? path.join(circleDir, "skills") : "";
    if (circleSkillsDir && fs.existsSync(circleSkillsDir)) {
      for (const entry of fs.readdirSync(circleSkillsDir, { withFileTypes: true })) {
        if (entry.isDirectory()) {
          const sm = path.join(circleSkillsDir, entry.name, "SKILL.md");
          if (fs.existsSync(sm)) paths.push(sm);
        } else if (entry.name.endsWith(".md")) {
          paths.push(path.join(circleSkillsDir, entry.name));
        }
      }
    }
  }

  return paths;
}

function getSkillMetadata(skillPath: string): { name: string; description: string; content: string } | null {
  try {
    const content = fs.readFileSync(skillPath, "utf-8");
    let name = path.basename(path.dirname(skillPath));
    if (name === "skills") name = path.basename(skillPath, ".md");
    let description = "Specialized capability package.";

    const fmMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (fmMatch) {
      const nameMatch = fmMatch[1].match(/^name:\s*(.+)$/m);
      if (nameMatch) name = nameMatch[1].trim();
      const descMatch = fmMatch[1].match(/^description:\s*(.+)$/m);
      if (descMatch) description = descMatch[1].trim();
    }

    return { name, description, content };
  } catch {
    return null;
  }
}

function buildSkillsAvailableXml(skillPaths: string[], loaded: Set<string>): string {
  const unloaded = skillPaths.filter(sp => {
    const meta = getSkillMetadata(sp);
    return meta && !loaded.has(meta.name);
  });

  if (unloaded.length === 0 && loaded.size === 0) return "";

  let result = "";

  if (unloaded.length > 0) {
    result += "\n\n<skills_available>\n";
    result += "Optional aids you can load via `load_skill` if useful. Do not load skills already in <loaded_skills>.\n";
    for (const sp of unloaded) {
      const meta = getSkillMetadata(sp);
      if (!meta) continue;
      result += "  <skill>\n";
      result += `    <name>${meta.name}</name>\n`;
      result += `    <description>${meta.description}</description>\n`;
      result += "  </skill>\n";
    }
    result += "</skills_available>";
  }

  if (loaded.size > 0) {
    result += "\n\n<loaded_skills>";
    for (const sp of skillPaths) {
      const meta = getSkillMetadata(sp);
      if (!meta || !loaded.has(meta.name)) continue;
      result += `\n\n# Skill: ${meta.name}\n\n${meta.content}`;
    }
    result += "\n</loaded_skills>";
  }

  return result;
}

function buildCenterContext(config: CircleConfig): string {
  const globalAgents = listGlobalAgents();
  const roster = config.agents.map(name => {
    const info = globalAgents.find(a => a.name === name);
    return info ? `- @${name} (${info.role}): ${info.description}` : `- @${name}`;
  }).join("\n");

  return `# Center — Circle Coordinator

You coordinate the "${config.name}" circle.

## Your Role
- Understand user requests and invoke the right agent using the \`invoke\` tool
- Summarize agent results and decide next steps
- Keep the user informed

## Available Agents
${roster}

## Rules
- Invoke one agent at a time
- After each agent, summarize before invoking the next
- You can answer simple coordination questions yourself
- When all work is done, report clearly to the user
`;
}

function buildActiveAgentCapsule(agentName: string, circleName: string | null, loaded: Set<string>): string {
  const isCenter = agentName === "center" && !!circleName;
  const agentContext = isCenter && circleName
    ? getCenterContext(circleName)
    : (getAgentMdContent(agentName) || "");
  const skills = getSkills(agentName, circleName, isCenter);
  const skillsContent = buildSkillsAvailableXml(skills, loaded);

  let header = `[Active Agent: @${agentName}]`;
  if (circleName) {
    const cfg = loadCircle(circleName);
    const allAgents = cfg ? ["center", ...cfg.agents] : ["center", agentName];
    const others = allAgents.filter(n => n !== agentName).map(n => "@" + n).join(", ");
    header += `\nCircle: ${circleName}`;
    if (others) header += `\nOther available agents: ${others}`;
  } else {
    header += `\nMode: point/global-agent`;
  }

  header += `\nYou are acting as @${agentName} for this request. Follow the agent instructions and skills below.`;

  return `${header}\n\n${agentContext}${skillsContent}`.trim();
}

interface AvailableModelLike {
  provider: string;
  id: string;
  name: string;
  reasoning?: boolean;
  contextWindow?: number;
  cost?: {
    input?: number;
    output?: number;
    cacheRead?: number;
    cacheWrite?: number;
  };
}

function getModelId(model: AvailableModelLike): string {
  return `${model.provider}/${model.id}`;
}

function getModelLabel(model: AvailableModelLike): string {
  return `${getModelId(model)} — ${model.name}`;
}

function getModelKeywordScore(text: string, strong: string[], weak: string[]): number {
  let score = 0;
  for (const token of strong) if (text.includes(token)) score += 1;
  for (const token of weak) if (text.includes(token)) score -= 1;
  return score;
}

function estimateModelStrength(model: AvailableModelLike): number {
  const text = `${model.provider} ${model.id} ${model.name}`.toLowerCase();
  const price = (model.cost?.input || 0) + (model.cost?.output || 0);

  return (
    (model.reasoning ? 4 : 0) +
    Math.min((model.contextWindow || 0) / 64_000, 4) +
    Math.min(price / 10, 4) +
    getModelKeywordScore(
      text,
      ["opus", "sonnet", "gpt-5", "gpt5", "o3", "o1", "r1", "reasoning", "grok-4", "pro", "large", "70b", "72b", "405b"],
      ["haiku", "mini", "small", "nano", "flash", "instant", "fast"]
    )
  );
}

function estimateTaskComplexity(task: SpawnTask): "simple" | "moderate" | "complex" {
  const text = task.task.toLowerCase();
  let score = 0;

  if (task.readOnly === false) score += 3;
  if (task.task.length > 800) score += 2;
  else if (task.task.length > 300) score += 1;

  if (/(architecture|trade-off|tradeoff|refactor|performance|security|audit|root cause|diagnose|debug|complex|large|comprehensive|deep|multi-step|synthesize|strategy|plan|investigate)/.test(text)) score += 3;
  if (/(research|compare|analyze|analysis|review|document)/.test(text)) score += 1;
  if (/(simple|quick|minor|small|brief|summarize|summary|list|scan|find|locate|grep|read-only|read only|easy)/.test(text)) score -= 1;

  if (score <= 1) return "simple";
  if (score <= 4) return "moderate";
  return "complex";
}

function suggestModelForTask(task: SpawnTask, availableModels: AvailableModelLike[], fallbackModel: string): string {
  if (task.model) return task.model;
  if (availableModels.length === 0) return fallbackModel;

  const ranked = [...availableModels].sort((a, b) => {
    const strengthDelta = estimateModelStrength(a) - estimateModelStrength(b);
    if (strengthDelta !== 0) return strengthDelta;
    return getModelId(a).localeCompare(getModelId(b));
  });

  const complexity = estimateTaskComplexity(task);
  if (complexity === "simple") return getModelId(ranked[0]);
  if (complexity === "complex") return getModelId(ranked[ranked.length - 1]);
  return getModelId(ranked[Math.floor((ranked.length - 1) / 2)]);
}

function buildSpawnPreviewResults(tasks: SpawnTask[]): SpawnResult[] {
  return tasks.map((task) => ({
    agent: task.agent,
    task: task.task,
    status: "failed",
    output: "(not started)",
    usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 },
    model: task.model,
  }));
}

// ─── Extension ───────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  let activeCircle: CircleConfig | null = null;
  let activeAgent: string = "center";
  let pointAgent: string | null = null; // Direct 1:1 with a global agent (no circle)
  let loadedSkills: Set<string> = new Set();

  // Track the last message from previous loop (for capsule positioning)
  // This is the message BEFORE which the capsule should be inserted
  let prevLoopLastMsg: unknown | null = null;

  // ─── Context Injection ─────────────────────────────────────────────

  // Note: circle-agent-label messages are no longer sent to the conversation.
  // Agent switches are tracked internally, and status is shown in the UI status bar only.
  // This keeps the context clean and focused on actual task content.

  pi.on("context", async (event, ctx) => {
    const currentAgent = pointAgent || activeAgent;
    const currentCircleName = pointAgent ? null : (activeCircle?.name || null);

    // No active agent/circle - skip
    if (!currentAgent || (!pointAgent && !activeCircle)) return;

    const capsule = buildActiveAgentCapsule(currentAgent, currentCircleName, loadedSkills);
    if (!capsule) return;

    const capsuleMessage = {
      role: "user" as const,
      content: `[Active Agent Context — injected by circle extension]\n\n${capsule}`,
      timestamp: Date.now(),
    };

    const messages = [...event.messages];
    
    // Sliding capsule logic (simplified):
    // - Remove old capsule
    // - Insert capsule just before the last message (handles all edge cases)
    //   - When prevLoopLastMsg exists: it will be in messages, insert after it
    //   - When prevLoopLastMsg is null/missing: insert before last message
    //   - This works for first turn, tree command, and normal turns
    
    // Step 1: Remove any previously injected capsule
    for (let i = messages.length - 1; i >= 0; i--) {
      const m = messages[i];
      if (m && "role" in m && m.role === "user" &&
          typeof m.content === "string" &&
          m.content.startsWith("[Active Agent Context — injected by circle extension]")) {
        messages.splice(i, 1);
        break;
      }
    }

    // Step 2: Find insertion point - insert capsule AFTER prevLoopLastMsg, or before last
    let insertAt = messages.length; // Default: at end
    
    // Try to find prevLoopLastMsg in messages
    if (prevLoopLastMsg) {
      for (let i = messages.length - 1; i >= 0; i--) {
        const m = messages[i];
        if (m === prevLoopLastMsg) {
          insertAt = i + 1;
          break;
        }
      }
    }
    
    // If prevLoopLastMsg not found or not in messages, insert before last message
    if (insertAt === messages.length && messages.length > 0) {
      insertAt = messages.length - 1;
    }

    messages.splice(insertAt, 0, capsuleMessage);

    // Step 3: Update prevLoopLastMsg for next turn
    prevLoopLastMsg = messages[messages.length - 1];

    return { messages };
  });


  // ─── User @agent-name Detection ───────────────────────────────────

  pi.on("input", async (event, ctx) => {
    if (!activeCircle) return { action: "continue" as const };

    const text = event.text.trim();
    const atMatch = text.match(/^@([\w-]+)\s+([\s\S]*)/);
    if (atMatch) {
      const target = atMatch[1];
      const message = atMatch[2];
      const allAgents = ["center", ...activeCircle.agents];
      if (allAgents.includes(target)) {
        activeAgent = target;
        loadedSkills.clear();
        ctx.ui.setStatus("circle", ctx.ui.theme.fg("warning", `🏛️ ${activeCircle.name} → @${activeAgent}`));
        return { action: "transform" as const, text: message };
      }
    }

    return { action: "continue" as const };
  });

  // ─── invoke Tool ───────────────────────────────────────────────────

  pi.registerTool({
    name: "load_skill",
    label: "Load Skill",
    description: "Load the full operational playbook for a specific skill. Use this when you need to apply a skill listed in your <skills_available> section. Pass 'list' to see all available skills and their descriptions.",
    promptSnippet: "Load the full operational playbook for a specific skill. Use this when you need to apply a skill listed in your <skills_available> section.",
    promptGuidelines: [
      "Use skills when the task clearly matches one of the available skill descriptions.",
      "Before loading a specific skill, first check the <skills_available> list in your active context and pick the best match.",
      "If you are unsure what skills are available, call load_skill with skill_name: 'list'.",
      "Skills listed in <loaded_skills> are already active — do NOT call load_skill for them again.",
      "Do not guess another agent's skills. If a needed skill belongs to another agent, use invoke to switch instead.",
      "Load the full skill before applying it; do not rely only on the short description.",
    ],
    parameters: Type.Object({
      skill_name: Type.String({ description: "The name of the skill to load. Use 'list' to see all skills available to you before choosing one." })
    }, { required: ["skill_name"] }),
    async execute(_toolCallId, args) {
      if (!args || !args.skill_name) {
        return { isError: true, content: [{ type: "text", text: "Missing skill_name parameter." }] };
      }

      const currentAgent = pointAgent || activeAgent;
      const currentCircleName = pointAgent ? null : (activeCircle?.name || null);
      const currentIsCenter = !pointAgent && currentAgent === "center";
      const skills = getSkills(currentAgent, currentCircleName, currentIsCenter);

      // Handle the special "list" command
      if (args.skill_name === "list") {
        if (skills.length === 0) {
          return { content: [{ type: "text", text: `No skills are currently available for @${currentAgent}.` }] };
        }

        let listStr = `### Available Skills for @${currentAgent}\n\n`;
        for (const sp of skills) {
          const meta = getSkillMetadata(sp);
          if (!meta) continue;
          const marker = loadedSkills.has(meta.name) ? " *(loaded)*" : "";
          listStr += `- **${meta.name}**: ${meta.description}${marker}\n`;
        }
        return { content: [{ type: "text", text: listStr }] };
      }

      // Try to find the specific skill
      for (const sp of skills) {
        const meta = getSkillMetadata(sp);
        if (!meta) continue;

        if (meta.name === args.skill_name) {
          if (loadedSkills.has(meta.name)) {
            return {
              content: [{ type: "text", text: `Skill '${meta.name}' is already loaded in your active context. No need to load it again.` }]
            };
          }
          loadedSkills.clear();
          loadedSkills.add(meta.name);
          return {
            content: [{ type: "text", text: `Skill '${meta.name}' loaded into your active context. It is now available in your agent instructions.` }],
            details: { skillName: meta.name, skillContent: meta.content },
          };
        }
      }
      
      // Not found for active agent. Check if it belongs to another global agent
      try {
        for (const agent of listGlobalAgents()) {
          const otherSkills = getSkills(agent.name, null, false);
          for (const sp of otherSkills) {
            const meta = getSkillMetadata(sp);
            if (!meta) continue;
            if (meta.name === args.skill_name) {
              return {
                isError: true,
                content: [{ type: "text", text: `Skill '${args.skill_name}' belongs to the '@${agent.name}' agent. Use the invoke tool to switch to that agent if you need this skill.` }]
              };
            }
          }
        }
      } catch {
        // Ignore errors in the fallback check
      }
      
      return {
        isError: true,
        content: [{ type: "text", text: `Skill '${args.skill_name}' not found.` }]
      };
    },
    renderCall(args, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("load_skill ")) + 
        theme.fg("accent", args.skill_name || "unknown"), 
        0, 0
      );
    },
    renderResult(result, options, theme) {
      const textPart = result.content.find((p) => p.type === "text");
      const statusText = textPart?.type === "text" ? textPart.text : "(no output)";
      const details = result.details as { skillName?: string; skillContent?: string } | undefined;

      if (options.expanded && details?.skillContent) {
        return new Text(`${statusText}\n\n${theme.fg("dim", "─── Skill Content ───")}\n${details.skillContent}`, 0, 0);
      }

      if (details?.skillContent) {
        return new Text(`${statusText}\n${theme.fg("dim", "(ctrl+o to view skill content)")}`, 0, 0);
      }

      return new Text(statusText, 0, 0);
    }
  });

  pi.registerTool({
    name: "invoke",
    label: "Invoke Agent",
    description: "Switch to another agent in the active circle, activate a circle, or point to any global agent. Use agent 'list' to see all available agents and circles. Call with agent 'center' to return to the coordinator.",
    promptSnippet: "Switch to another agent, activate a circle, or use 'list' to see what's available",
    promptGuidelines: [
      "Use invoke to delegate specialist work to the appropriate circle agent.",
      "After invoke, the next LLM response uses the invoked agent's context and skills.",
      "Invoked agents see the current conversation context — do NOT repeat context already discussed. Only provide: specific action + new info + constraints.",
      "This is the OPPOSITE of spawn: with invoke, agent already has context. With spawn, agent has nothing.",
      "After specialist work is finished, return control to center with invoke(agent: 'center').",
      "Use invoke with agent 'center' to return control to the coordinator.",
      "Use invoke with a 'circle' parameter to activate or switch to a different circle.",
      "Use invoke with just an agent name (no circle active) to point directly to any global agent.",
    ],
    parameters: Type.Object({
      agent: Type.String({ description: "Name of the agent to invoke (e.g., 'visionary', 'critic', 'center')" }),
      task: Type.Optional(Type.String({ description: "Task/instruction for the invoked agent" })),
      circle: Type.Optional(Type.String({ description: "Circle to activate or switch to (optional)" })),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const prev = activeAgent;
      const prevCircle = activeCircle?.name || null;

      // Special: list available agents and circles
      if (params.agent === "list") {
        const globalAgents = listGlobalAgents();
        const circles = listCircles();
        const lines: string[] = [];
        if (activeCircle) {
          lines.push(`Active circle: ${activeCircle.name}`);
          lines.push(`  Circle agents: ${["center", ...activeCircle.agents].join(", ")}`);
          lines.push("");
        }
        if (circles.length > 0) {
          lines.push("Available circles:");
          for (const c of circles) lines.push(`  - ${c.name}: ${c.description} [${c.agents.join(", ")}]`);
          lines.push("");
        }
        if (globalAgents.length > 0) {
          lines.push("Global agents (invokable from anywhere):");
          for (const a of globalAgents) lines.push(`  - @${a.name} (${a.role}): ${a.description}`);
        }
        if (lines.length === 0) lines.push("No agents or circles available.");
        return { content: [{ type: "text", text: lines.join("\n") }], details: { action: "list" } };
      }

      // Case 1: Activate/switch a circle
      if (params.circle) {
        const circle = loadCircle(params.circle);
        if (!circle) {
          const available = listCircles().map(c => c.name).join(", ") || "none";
          throw new Error(`Circle "${params.circle}" not found. Available: ${available}`);
        }
        activeCircle = circle;
        pointAgent = null;
        loadedSkills.clear();

        const allAgents = ["center", ...circle.agents];
        if (params.agent && allAgents.includes(params.agent)) {
          activeAgent = params.agent;
        } else if (params.agent && params.agent !== "center") {
          throw new Error(`"@${params.agent}" not in circle "${circle.name}". Available: ${allAgents.join(", ")}`);
        } else {
          activeAgent = "center";
        }

        ctx.ui.setStatus("circle", ctx.ui.theme.fg("warning", `\u{1F3DB}\uFE0F ${circle.name} \u2192 @${activeAgent}`));

        let response = prevCircle
          ? `Switched circle: ${prevCircle} \u2192 ${circle.name}, active: @${activeAgent}`
          : `Activated circle: ${circle.name}, active: @${activeAgent}`;
        if (params.task) response += `\nTask: ${params.task}`;
        return { content: [{ type: "text", text: response }], details: { previousCircle: prevCircle, newCircle: circle.name, agent: activeAgent, task: params.task } };
      }

      // Case 2: Active circle — invoke agent within it
      if (activeCircle) {
        const allAgents = ["center", ...activeCircle.agents];

        // Agent is in the circle
        if (allAgents.includes(params.agent)) {
          activeAgent = params.agent;
          pointAgent = null;
          loadedSkills.clear();
          ctx.ui.setStatus("circle", ctx.ui.theme.fg("warning", `\u{1F3DB}\uFE0F ${activeCircle.name} \u2192 @${activeAgent}`));

          let response = `Switched: @${prev} \u2192 @${params.agent}`;
          if (params.task) response += `\nTask: ${params.task}`;
          return { content: [{ type: "text", text: response }], details: { previousAgent: prev, newAgent: params.agent, task: params.task } };
        }

        // Agent NOT in circle — try as a global point agent
        const globalAgent = getAgentMdContent(params.agent);
        if (globalAgent) {
          pointAgent = params.agent;
          activeAgent = params.agent;
          loadedSkills.clear();
          ctx.ui.setStatus("circle", ctx.ui.theme.fg("accent", `\u{1F3AF} @${params.agent} (from ${activeCircle.name})`));
          let response = `Point: @${params.agent} (global agent, outside circle)`;
          if (params.task) response += `\nTask: ${params.task}`;
          response += `\nUse invoke with agent 'center' to return to the circle.`;
          return { content: [{ type: "text", text: response }], details: { previousAgent: prev, newAgent: params.agent, task: params.task, mode: "point" } };
        }

        throw new Error(`"@${params.agent}" not in circle "${activeCircle.name}" and not found globally. Circle agents: ${allAgents.join(", ")}. Global agents: ${listGlobalAgents().map(a => a.name).join(", ") || "none"}`);
      }

      // Case 3: No circle active — "center" means deactivate point session
      if (params.agent === "center" && pointAgent) {
        const prev = pointAgent;
        pointAgent = null;
        activeAgent = "center";
        loadedSkills.clear();
        ctx.ui.setStatus("circle", undefined);
        return { content: [{ type: "text", text: `Point session ended. @${prev} → normal mode.` }], details: { previousAgent: prev, mode: "off" } };
      }

      // Case 4: No circle active — point to any global agent
      const globalAgent = getAgentMdContent(params.agent);
      if (globalAgent) {
        pointAgent = params.agent;
        activeAgent = params.agent;
        loadedSkills.clear();
        ctx.ui.setStatus("circle", ctx.ui.theme.fg("accent", `\u{1F3AF} @${params.agent}`));
        let response = `Point: @${params.agent}`;
        if (params.task) response += `\nTask: ${params.task}`;
        return { content: [{ type: "text", text: response }], details: { newAgent: params.agent, task: params.task, mode: "point" } };
      }

      // Nothing matched
      const globalNames = listGlobalAgents().map(a => a.name).join(", ") || "none";
      const circleNames = listCircles().map(c => c.name).join(", ") || "none";
      throw new Error(`"@${params.agent}" not found. Global agents: ${globalNames}. Circles: ${circleNames}. Provide 'circle' parameter to activate a circle.`);
    },
  });

  // ─── Spawn Tool (Parallel Sub-Agents) ────────────────────────────────

  const SpawnTaskSchema = Type.Object({
    agent: Type.String({ description: "Name of the global agent to invoke" }),
    task: Type.String({ description: "SELF-CONTAINED task with ALL context the agent needs. Agent cannot see session history \u2014 this is their only input. Include relevant file contents, background, and constraints." }),
    model: Type.Optional(Type.String({ description: "Model override. Default: heuristic suggestion based on task difficulty and available models." })),
    readOnly: Type.Optional(Type.Boolean({ description: "If true (default), agent can only read. If false, agent can write/edit/bash. Use false for documentation writing to non-overlapping paths." })),
    writePaths: Type.Optional(Type.Array(Type.String(), { description: "When readOnly=false, declare which file paths/directories this task will write to. Informational for transparency." })),
  });

  const SpawnParams = Type.Object({
    tasks: Type.Array(SpawnTaskSchema, {
      description: "Independent read-only tasks to execute in parallel. Max 8. Agents get: read, grep, find, ls, web_search, web_fetch.",
      minItems: 2,
      maxItems: 8,
    }),
  });

  interface SpawnDetails {
    circle: string;
    results: SpawnResult[];
  }

  pi.registerTool({
    name: "spawn",
    label: "Spawn",
    description: "Spawn parallel isolated agents for independent tasks. Each agent runs in a separate process and CANNOT see session history \u2014 provide ALL needed context in the task field. Results return to center. Before execution, spawn suggests models from task difficulty and available models; the user can accept or override them. Default: read-only. Set readOnly=false for write-capable agents (documentation, file creation).",
    promptSnippet: "Spawn parallel isolated agents for independent tasks. Spawn suggests sub-agent models from task difficulty; the user can accept or override them.",
    promptGuidelines: [
      "spawn creates ISOLATED processes \u2014 spawned agents CANNOT see this conversation. The task field is their ONLY context. Include everything they need to know.",
      "This is the OPPOSITE of invoke: with invoke, don't repeat context (agent sees history). With spawn, you MUST provide full context (agent sees nothing else).",
      "ONLY use spawn when you are CERTAIN tasks are independent \u2014 no file overlap, no dependency between tasks, no shared decisions. Each task must be able to complete fully and return without needing input from other tasks or the user.",
      "Spawned tasks run to completion and return results to you (center). They cannot ask clarifying questions, cannot interact with the user, cannot wait for other tasks. They must be self-sufficient with the context you provide.",
      "Use spawn for 2-8 independent READ-ONLY tasks (research, analysis, review of separate areas).",
      "Before spawning: read relevant files yourself, then pass their content in the task description if the spawned agent needs it.",
      "spawn is only available when center is active. Cannot be used after invoking another agent.",
      "Safe to spawn: web research, file reading/analysis, code review of separate areas, documentation analysis.",
      "NOT safe to spawn: code writing, design decisions, anything that needs other tasks' output or session context that's too large to pass.",
      "Before spawn execution, inspect available models and assign suggested models by task difficulty: cheaper/smaller for simple tasks, stronger for complex tasks.",
      "The user can accept all suggested models, force the parent model for all, choose per-sub-agent models, or choose one model for all.",
      "If the user does not respond in time, default to the suggested models for all sub-agents.",
      "Prefer invoke for primary workflow (shared context, sequential). Use spawn only for genuinely independent parallel work.",
      "Write mode (readOnly=false): Use for parallel documentation writing to NON-OVERLAPPING paths. Each task must write to DIFFERENT files/directories. Declare writePaths for transparency.",
      "Write mode safety: never have two write tasks target the same file or directory. Center should update shared indexes AFTER spawn completes, not during.",
    ],
    parameters: SpawnParams,

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      // Guard: must be in a circle with center active
      if (!activeCircle) {
        throw new Error("No circle active. Use /circle to activate one.");
      }
      if (activeAgent !== "center") {
        throw new Error("Only center can spawn parallel tasks. Return to center first.");
      }

      // Validate agents exist
      for (const task of params.tasks) {
        if (!getAgentMdContent(task.agent)) {
          throw new Error(`Agent \"@${task.agent}\" not found in project overrides, user overrides, or bundled defaults. Available: ${listGlobalAgents().map(a => a.name).join(", ")}`);
        }
      }

      // Resolve model selections interactively before launching subprocesses
      const currentModel = ctx.model;
      const parentModelId = currentModel ? `${currentModel.provider}/${currentModel.id}` : "anthropic/claude-haiku-4-5";
      const parentModelLabel = currentModel ? `${parentModelId} — ${currentModel.name}` : parentModelId;
      const availableModels = ctx.modelRegistry.getAvailable() as AvailableModelLike[];
      const sortedModels = [...availableModels].sort((a, b) => getModelId(a).localeCompare(getModelId(b)));
      const suggestedTasks = (params.tasks as SpawnTask[]).map((task) => ({
        ...task,
        model: suggestModelForTask(task, sortedModels, parentModelId),
      }));
      let resolvedTasks = suggestedTasks.map((task) => ({ ...task }));
      const MODEL_SELECTION_TIMEOUT_MS = 90_000;

      const pushModelSelectionPreview = (headline: string, tasksForPreview: SpawnTask[]) => {
        if (!onUpdate) return;
        onUpdate({
          content: [{ type: "text", text: headline }],
          details: { circle: activeCircle!.name, results: buildSpawnPreviewResults(tasksForPreview) } as SpawnDetails,
        });
      };

      pushModelSelectionPreview("Spawn: choosing models (showing suggestions)", resolvedTasks);

      if (ctx.hasUI && sortedModels.length > 0) {
        const modelOptions = sortedModels.map((m) => ({ id: getModelId(m), label: getModelLabel(m) }));
        const modelByLabel = new Map(modelOptions.map((m) => [m.label, m.id]));
        const useSuggestedForAll = "Use suggested models for all";
        const useParentForAll = `Choose current (parent) agent's model for all — ${parentModelLabel}`;
        const selectModelForAll = "Select a model for all";

        for (let i = 0; i < resolvedTasks.length; i++) {
          const task = resolvedTasks[i];
          const selection = await ctx.ui.select(
            `Spawn model for @${task.agent} (${i + 1}/${resolvedTasks.length})`,
            [useSuggestedForAll, useParentForAll, ...modelOptions.map((m) => m.label), selectModelForAll],
            { signal, timeout: MODEL_SELECTION_TIMEOUT_MS },
          );

          if (!selection || selection === useSuggestedForAll) {
            resolvedTasks = suggestedTasks.map((t) => ({ ...t }));
            pushModelSelectionPreview("Spawn: using suggested models", resolvedTasks);
            break;
          }

          if (selection === useParentForAll) {
            resolvedTasks = resolvedTasks.map((t) => ({ ...t, model: parentModelId }));
            pushModelSelectionPreview("Spawn: using parent model for all", resolvedTasks);
            break;
          }

          if (selection === selectModelForAll) {
            const allChoice = await ctx.ui.select(
              "Select a model for all sub-agents",
              modelOptions.map((m) => m.label),
              { signal, timeout: MODEL_SELECTION_TIMEOUT_MS },
            );
            if (!allChoice) {
              resolvedTasks = suggestedTasks.map((t) => ({ ...t }));
              pushModelSelectionPreview("Spawn: using suggested models", resolvedTasks);
              break;
            }
            const chosenId = modelByLabel.get(allChoice);
            if (!chosenId) {
              throw new Error(`Unknown model selection: ${allChoice}`);
            }
            resolvedTasks = resolvedTasks.map((t) => ({ ...t, model: chosenId }));
            pushModelSelectionPreview("Spawn: using one chosen model for all", resolvedTasks);
            break;
          }

          const chosenId = modelByLabel.get(selection);
          if (!chosenId) {
            throw new Error(`Unknown model selection: ${selection}`);
          }
          resolvedTasks[i] = { ...task, model: chosenId };
          pushModelSelectionPreview(`Spawn: selected ${i + 1}/${resolvedTasks.length} models`, resolvedTasks);
        }
      }

      // Run parallel tasks
      const results = await runSpawnTasks(
        resolvedTasks,
        ctx.cwd,
        signal,
        parentModelId,
        getAgentMdContent,
        (name) => resolveGlobalAgentDir(name) || getGlobalAgentDir(name),
        (partialResults) => {
          if (onUpdate) {
            const succeeded = partialResults.filter(r => r.status === "success").length;
            const running = partialResults.filter(r => r.status === "failed" && r.output === "(not started)").length;
            const total = partialResults.length;
            onUpdate({
              content: [{ type: "text", text: `Spawn: ${succeeded}/${total} done, ${total - succeeded - running} running...` }],
              details: { circle: activeCircle!.name, results: partialResults } as SpawnDetails,
            });
          }
        },
      );

      // Format final response
      const succeeded = results.filter(r => r.status === "success").length;
      let text = `Spawn: ${succeeded}/${results.length} succeeded\n`;

      for (const r of results) {
        const icon = r.status === "success" ? "\u2713" : r.status === "timeout" ? "\u23f0" : "\u2717";
        text += `\n### [${icon}] @${r.agent}\n\n`;
        if (r.error) text += `**Error:** ${r.error}\n\n`;
        text += r.output + "\n";
      }

      return {
        content: [{ type: "text", text }],
        details: { circle: activeCircle.name, results } as SpawnDetails,
      };
    },

    renderCall(args, theme, _context) {
      const tasks = (args.tasks || []) as Array<{ agent: string; task: string; readOnly?: boolean }>;
      const circleName = activeCircle?.name || "";
      const hasTruncatedTasks = tasks.some((t) => t.task.length > 55 || t.task.includes("\n"));

      let text = theme.fg("toolTitle", theme.bold("spawn ")) +
        theme.fg("accent", `${tasks.length} agents`) +
        (circleName ? theme.fg("muted", ` [${circleName}]`) : "");

      for (const t of tasks) {
        const mode = t.readOnly === false ? theme.fg("warning", "W") : theme.fg("success", "R");
        const singleLineTask = t.task.replace(/\s+/g, " ").trim();
        const preview = singleLineTask.length > 55 ? singleLineTask.slice(0, 55) + "..." : singleLineTask;
        text += `\n  ${mode} ${theme.fg("accent", "@" + t.agent)} ${theme.fg("dim", preview)}`;
      }

      if (hasTruncatedTasks) {
        text += `\n${theme.fg("muted", "(Ctrl+O to expand tasks)")}`;
      }

      return new Text(text, 0, 0);
    },

    renderResult(result, { expanded }, theme, context) {
      const details = result.details as SpawnDetails | undefined;
      if (!details || !details.results || details.results.length === 0) {
        const text = result.content[0];
        return new Text(text?.type === "text" ? text.text : "(no output)", 0, 0);
      }

      const results = details.results;
      const taskArgs = ((context.args as { tasks?: Array<{ agent: string; task: string; readOnly?: boolean }> } | undefined)?.tasks || []);
      const hasTaskDetail = taskArgs.length > 0;
      const hasExpandableTasks = taskArgs.some((t) => t.task.length > 55 || t.task.includes("\n"));
      const succeeded = results.filter(r => r.status === "success").length;
      const total = results.length;
      const allDone = results.every(r => r.status !== "failed" || r.output !== "(not started)");

      const icon = !allDone
        ? theme.fg("warning", "\u23f3")
        : succeeded === total
          ? theme.fg("success", "\u2713")
          : theme.fg("warning", "\u25d0");

      let text = `${icon} ${theme.fg("toolTitle", theme.bold("spawn "))}${theme.fg("accent", `${succeeded}/${total} succeeded`)}`;

      if (!expanded && hasExpandableTasks) {
        text += `\n${theme.fg("muted", "(Ctrl+O to expand tasks)")}`;
      }

      if (expanded && hasTaskDetail) {
        text += `\n\n${theme.fg("muted", "Tasks:")}`;
        for (const [i, task] of taskArgs.entries()) {
          const mode = task.readOnly === false ? theme.fg("warning", "W") : theme.fg("success", "R");
          text += `\n${theme.fg("muted", "\u2500\u2500\u2500 ")}${mode} ${theme.fg("accent", "@" + task.agent)}`;
          const lines = task.task.split("\n");
          for (const line of lines) {
            text += `\n  ${theme.fg("toolOutput", line)}`;
          }
          if (i < taskArgs.length - 1) text += "\n";
        }
      }

      for (const [i, r] of results.entries()) {
        const rIcon = r.status === "success"
          ? theme.fg("success", "\u2713")
          : r.output === "(not started)"
            ? theme.fg("warning", "\u23f3")
            : theme.fg("error", "\u2717");

        const secs = r.elapsed != null ? `${(r.elapsed / 1000).toFixed(1)}s` : undefined;
        const headerMeta = [secs, r.model].filter(Boolean).join(" • ");

        text += `\n\n${theme.fg("muted", "\u2500\u2500\u2500 ")}${theme.fg("accent", "@" + r.agent)} ${rIcon}` +
          (headerMeta ? ` ${theme.fg("dim", headerMeta)}` : "");

        if (expanded && taskArgs[i]?.task) {
          text += `\n  ${theme.fg("muted", "Task:")}`;
          for (const line of taskArgs[i].task.split("\n")) {
            text += `\n  ${theme.fg("toolOutput", line)}`;
          }
        }

        if (r.error) {
          text += `\n  ${theme.fg("error", r.error)}`;
        } else if (r.output && r.output !== "(not started)") {
          const outputLines = expanded ? r.output.split("\n") : r.output.split("\n").slice(0, 3);
          for (const line of outputLines) {
            const preview = !expanded && line.length > 70 ? line.slice(0, 70) + "..." : line;
            text += `\n  ${theme.fg("toolOutput", preview)}`;
          }
          if (!expanded && r.output.split("\n").length > 3) {
            text += `\n  ${theme.fg("muted", `... (${r.output.split("\n").length - 3} more lines)`)}`;
          }
        } else {
          const pendingLabel = r.output === "(not started)"
            ? (r.elapsed != null ? "(starting...)" : "(pending...)")
            : "(running...)";
          text += `\n  ${theme.fg("muted", pendingLabel)}`;
        }

        const usageStr = formatUsageStats(r.usage, r.model, r.elapsed);
        if (usageStr && r.status !== "failed") {
          text += `\n  ${theme.fg("dim", usageStr)}`;
        }
      }

      const totalUsage = {
        input: results.reduce((s, r) => s + r.usage.input, 0),
        output: results.reduce((s, r) => s + r.usage.output, 0),
        cacheRead: results.reduce((s, r) => s + r.usage.cacheRead, 0),
        cacheWrite: results.reduce((s, r) => s + r.usage.cacheWrite, 0),
        cost: results.reduce((s, r) => s + r.usage.cost, 0),
        turns: results.reduce((s, r) => s + r.usage.turns, 0),
      };
      const maxElapsed = Math.max(...results.map(r => r.elapsed || 0));
      const totalStr = formatUsageStats(totalUsage, undefined, maxElapsed);
      if (totalStr) {
        text += `\n\n${theme.fg("dim", `Total: ${totalStr}`)}`;
      }

      return new Text(text, 0, 0);
    },
  });

  // ─── Commands ──────────────────────────────────────────────────────

  pi.registerCommand("circle", {
    description: "Activate a circle",
    handler: async (args, ctx) => {
      const circles = listCircles();
      if (circles.length === 0) { ctx.ui.notify("No circles. Use /circle-create.", "warning"); return; }

      let name: string | undefined;
      if (args?.trim()) {
        name = args.trim();
      } else {
        const choice = await ctx.ui.select("Activate circle:", circles.map(c => `${c.name} — ${c.description} (${c.agents.length} agents)`));
        if (choice) name = choice.split(" — ")[0];
      }
      if (!name) return;

      const circle = loadCircle(name);
      if (!circle) { ctx.ui.notify(`"${name}" not found.`, "error"); return; }

      // Verify agents exist
      const missing = circle.agents.filter(a => !getAgentMdContent(a));
      if (missing.length > 0) {
        ctx.ui.notify(`Warning: agents not found in project overrides, user overrides, or bundled defaults: ${missing.join(", ")}`, "warning");
      }

      activeCircle = circle;
      activeAgent = "center";

      ctx.ui.setStatus("circle", ctx.ui.theme.fg("warning", `🏛️ ${circle.name} → @center`));
      ctx.ui.notify(
        `Circle "${circle.name}" active.\nAgents: ${circle.agents.map(a => "@" + a).join(", ")}\nUse @agent-name to invoke directly.`,
        "success"
      );
    },
  });

  pi.registerCommand("circle-off", {
    description: "Deactivate the current circle or point session",
    handler: async (_args, ctx) => {
      if (!activeCircle && !pointAgent) { ctx.ui.notify("Nothing active.", "info"); return; }
      const label = activeCircle ? `Circle "${activeCircle.name}"` : `Point @${pointAgent}`;
      clearCircleState();
      ctx.ui.setStatus("circle", undefined);
      ctx.ui.notify(`${label} deactivated.`, "info");
    },
  });

  pi.registerCommand("circle-point", {
    description: "Chat directly with a single global agent (no circle, no center)",
    handler: async (args, ctx) => {
      const agents = listGlobalAgents();
      if (agents.length === 0) { ctx.ui.notify("No global agents found. Create one in .pi/agent/agents/<name>/AGENT.md or your user agent directory.", "warning"); return; }

      let name: string | undefined;
      if (args?.trim()) {
        name = args.trim();
        if (!agents.find(a => a.name === name)) { ctx.ui.notify(`Agent "@${name}" not found.`, "error"); return; }
      } else {
        const choice = await ctx.ui.select("Point to agent:", agents.map(a => `${a.name} — ${a.role}`));
        if (choice) name = choice.split(" — ")[0];
      }
      if (!name) return;

      // Deactivate any circle and clear state
      clearCircleState();
      pointAgent = name;

      ctx.ui.setStatus("circle", ctx.ui.theme.fg("accent", `🎯 @${pointAgent}`));
      ctx.ui.notify(`Point mode: @${name}. All messages go directly to this agent.\nUse /circle-off to return to normal.`, "success");
    },
  });

  pi.registerCommand("circle-create", {
    description: "Create a new circle",
    handler: async (_args, ctx) => {
      const available = listGlobalAgents();
      const hint = available.length > 0
        ? `\n\nAvailable global agents: ${available.map(a => a.name).join(", ")}`
        : "\n\nNo global agents found yet. Create them in .pi/agent/agents/<name>/AGENT.md or your user agent directory.";

      const template = JSON.stringify({
        name: "my-circle",
        description: "What this circle does",
        agents: available.slice(0, 3).map(a => a.name),
      }, null, 2);

      const edited = await ctx.ui.editor(`Define circle (agents list references global agents):${hint}`, template);
      if (!edited) return;
      try {
        const c: CircleConfig = JSON.parse(edited);
        if (!c.name || !c.agents?.length) { ctx.ui.notify("Need name + at least one agent.", "error"); return; }
        c.createdAt = new Date().toISOString();
        c.updatedAt = new Date().toISOString();
        saveCircle(c);
        ctx.ui.notify(`"${c.name}" created!\n📁 ${getCircleDir(c.name)}\nCenter: ${getCenterDir(c.name)}/AGENT.md`, "success");
      } catch (e: any) { ctx.ui.notify(`Invalid JSON: ${e.message}`, "error"); }
    },
  });

  pi.registerCommand("circle-list", {
    description: "List circles",
    handler: async (_args, ctx) => {
      const circles = listCircles();
      if (circles.length === 0) { ctx.ui.notify("No circles. /circle-create to make one.", "info"); return; }
      const active = activeCircle?.name;
      const lines = circles.map(c => {
        const marker = c.name === active ? "▶ " : "  ";
        return `${marker}🏛️ ${c.name} — ${c.description}\n    Agents: ${c.agents.map(a => "@" + a).join(", ")}`;
      });
      ctx.ui.notify(lines.join("\n\n"), "info");
    },
  });

  pi.registerCommand("circle-agents", {
    description: "List global agents available for circles",
    handler: async (_args, ctx) => {
      const agents = listGlobalAgents();
      if (agents.length === 0) {
        ctx.ui.notify(`No agents found.\nCreate them in .pi/agent/agents/<name>/AGENT.md or your user agent directory.`, "info");
        return;
      }
      const lines = agents.map(a => `• @${a.name} (${a.role})\n  ${a.description}`);
      ctx.ui.notify(`Global agents (${agents.length}):\n\n${lines.join("\n\n")}\n\n📁 ${getGlobalAgentsDir()}`, "info");
    },
  });

  pi.registerCommand("circle-edit", {
    description: "Edit a circle's config",
    handler: async (args, ctx) => {
      const circles = listCircles();
      if (circles.length === 0) { ctx.ui.notify("None.", "info"); return; }
      const name = args?.trim() || (await ctx.ui.select("Edit:", circles.map(c => c.name)) ?? undefined);
      if (!name) return;
      const circle = loadCircle(name);
      if (!circle) { ctx.ui.notify("Not found.", "error"); return; }
      const edited = await ctx.ui.editor(`Edit ${name}:`, JSON.stringify(circle, null, 2));
      if (!edited) return;
      try {
        const u: CircleConfig = JSON.parse(edited);
        u.createdAt = circle.createdAt;
        saveCircle(u);
        if (activeCircle?.name === name) activeCircle = u;
        ctx.ui.notify("Updated!", "success");
      } catch (e: any) { ctx.ui.notify(`Invalid: ${e.message}`, "error"); }
    },
  });

  pi.registerCommand("circle-delete", {
    description: "Delete a circle",
    handler: async (args, ctx) => {
      const circles = listCircles();
      if (circles.length === 0) { ctx.ui.notify("None.", "info"); return; }
      const name = args?.trim() || (await ctx.ui.select("Delete:", circles.map(c => c.name)) ?? undefined);
      if (!name) return;
      if (!(await ctx.ui.confirm("Delete?", `Delete "${name}"? (Global agents are NOT deleted)`))) return;
      if (activeCircle?.name === name) { activeCircle = null; activeAgent = "center"; loadedSkills.clear(); ctx.ui.setStatus("circle", undefined); }
      deleteCircle(name) ? ctx.ui.notify("Deleted. Global agents untouched.", "success") : ctx.ui.notify("Not found.", "error");
    },
  });

  // ─── Session Lifecycle ─────────────────────────────────────────────


  // Clear circle state (for /circle-off or session end)
  function clearCircleState() {
    activeCircle = null;
    activeAgent = "center";
    pointAgent = null;
    loadedSkills.clear();
    prevLoopLastMsg = null;
  }

  pi.on("session_start", async (_event, _ctx) => {
    activeCircle = null;
    activeAgent = "center";
    pointAgent = null;

    loadedSkills.clear();
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    clearCircleState();
    ctx.ui.setStatus("circle", undefined);
  });

  // ─── Agent Label Renderer ──────────────────────────────────────────

  pi.registerMessageRenderer("circle-agent-label", (message, _options, theme) => {
    const details = message.details as { agent: string; circle?: string; mode: string } | undefined;
    const agentName = details?.agent || message.content || "unknown";
    const circleName = details?.circle;

    let label: string;
    if (details?.mode === "point") {
      label = theme.fg("accent", `🎯 @${agentName}`);
    } else {
      label = theme.fg("warning", `🏛️ @${agentName}`) + (circleName ? theme.fg("dim", ` (${circleName})`) : "");
    }

    return new Text(label, 0, 0);
  });
}
