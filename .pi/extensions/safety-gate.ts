import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { existsSync, realpathSync } from "node:fs";
import { basename, dirname, resolve } from "node:path";

export type CommandDecision =
	| { action: "block" | "confirm"; reason: string }
	| undefined;

const blockedCommands: Array<[RegExp, string]> = [
	[/\bgit\s+reset\s+--hard\b/i, "destructive git reset is prohibited"],
	[/\bgit\s+push\b[^\n;&|]*(?:--force(?:-with-lease)?|-f(?:\s|$))/i, "force push is prohibited"],
];

const confirmationCommands: Array<[RegExp, string]> = [
	[/\brm\b(?=[^\n;&|]*\s(?:-[A-Za-z]*r[A-Za-z]*|--recursive)(?:\s|$))(?=[^\n;&|]*\s(?:-[A-Za-z]*f[A-Za-z]*|--force)(?:\s|$))[^\n;&|]*/i, "recursive forced deletion requires confirmation"],
	[/\bsudo\b/i, "privilege escalation requires confirmation"],
	[/\bgit\s+branch\s+-D\b|\bgit\s+push\b[^\n;&|]*--delete\b/i, "branch deletion requires confirmation"],
	[/\b(?:goose|migrate)\b[^\n;&|]*(?:\bdown\b|\breset\b|\bdrop\b)|\bDROP\s+(?:DATABASE|TABLE|SCHEMA)\b/i, "destructive migration requires confirmation"],
	[/\b(?:terraform\s+(?:apply|destroy)|kubectl\s+(?:apply|delete)|helm\s+(?:install|upgrade|uninstall)|ansible-playbook|gh\s+release\s+create)\b/i, "deployment operation requires confirmation"],
	[/\bpvesh\b|\/api2\/json\b|\bPVE_(?:HOST|TOKEN|PASSWORD)\b/i, "PVE access requires confirmation"],
];

function canonicalPath(inputPath: string, cwd: string): string {
	let existing = resolve(cwd, inputPath);
	const missing: string[] = [];
	while (!existsSync(existing) && dirname(existing) !== existing) {
		missing.unshift(basename(existing));
		existing = dirname(existing);
	}
	return resolve(realpathSync(existing), ...missing).replaceAll("\\", "/");
}

export function isProtectedPath(inputPath: string, cwd: string): boolean {
	const path = canonicalPath(inputPath, cwd);
	const root = realpathSync(resolve(cwd)).replaceAll("\\", "/");
	const relative = root === path ? "" : path.slice(root.length + 1);

	return (
		/(^|\/)\.env(?:\.[^/]*)?$/.test(path) ||
		/(^|\/)(?:\.git|\.ssh|\.aws|credentials?|secrets?)(\/|$)/i.test(path) ||
		/(^|\/)\.config\/cloudpilot-pve-pr-bot(\/|$)/i.test(path) ||
		/\.(?:pem|key)$/i.test(path) ||
		relative === "web/src/api/schema.d.ts"
	);
}

export function classifyCommand(command: string): CommandDecision {
	for (const [pattern, reason] of blockedCommands) {
		if (pattern.test(command)) return { action: "block", reason };
	}
	for (const [pattern, reason] of confirmationCommands) {
		if (pattern.test(command)) return { action: "confirm", reason };
	}
	return undefined;
}

export async function commandBlockReason(
	command: string,
	confirm?: (reason: string) => Promise<boolean>,
): Promise<string | undefined> {
	const decision = classifyCommand(command);
	if (!decision) return undefined;
	if (decision.action === "block") return decision.reason;
	if (!confirm || !(await confirm(decision.reason))) {
		return `${decision.reason}; explicit confirmation was not granted`;
	}
	return undefined;
}

export default function safetyGate(pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName === "write" || event.toolName === "edit") {
			const path = (event.input as { path?: unknown }).path;
			if (typeof path === "string" && isProtectedPath(path, ctx.cwd)) {
				return { block: true, reason: `Protected path: ${path}` };
			}
		}

		if (event.toolName !== "bash") return undefined;
		const command = (event.input as { command?: unknown }).command;
		if (typeof command !== "string") return undefined;

		const reason = await commandBlockReason(
			command,
			ctx.hasUI
				? (message) => ctx.ui.confirm("Safety gate", message, { timeout: 30_000 })
				: undefined,
		);
		return reason ? { block: true, reason } : undefined;
	});
}
