import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, rmSync, symlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
	classifyCommand,
	commandBlockReason,
	isProtectedPath,
} from "../extensions/safety-gate.ts";

test("protects credentials and generated API types", () => {
	const cwd = mkdtempSync(join(tmpdir(), "cloudpilot-safety-"));
	try {
		for (const path of [
			".env",
			".env.production",
			"/root/.ssh/id_ed25519",
			"/root/.config/cloudpilot-pve-pr-bot/private-key.pem",
			"web/src/api/schema.d.ts",
		]) {
			assert.equal(isProtectedPath(path, cwd), true, path);
		}
		assert.equal(isProtectedPath("web/src/App.vue", cwd), false);
		assert.equal(isProtectedPath("api/openapi.yaml", cwd), false);
	} finally {
		rmSync(cwd, { recursive: true, force: true });
	}
});

test("resolves symlinks before checking protected paths", () => {
	const root = mkdtempSync(join(tmpdir(), "cloudpilot-safety-"));
	try {
		mkdirSync(join(root, "credentials"));
		symlinkSync(join(root, "credentials"), join(root, "alias"));
		assert.equal(isProtectedPath("alias/token", root), true);
	} finally {
		rmSync(root, { recursive: true, force: true });
	}
});

test("prohibits destructive git operations", () => {
	assert.equal(classifyCommand("git reset --hard HEAD")?.action, "block");
	assert.equal(classifyCommand("git push --force-with-lease origin main")?.action, "block");
});

test("classifies confirmation-gated operations", () => {
	for (const command of [
		"rm -rf build",
		"rm -r -f build",
		"sudo systemctl restart cloudpilot",
		"git branch -D old-work",
		"goose postgres connection down",
		"terraform apply",
		"pvesh get /nodes",
	]) {
		assert.equal(classifyCommand(command)?.action, "confirm", command);
	}
	assert.equal(classifyCommand("go test ./..."), undefined);
});

test("fails closed when confirmation is denied or unavailable", async () => {
	assert.match(await commandBlockReason("rm -rf build"), /not granted/);
	assert.match(
		await commandBlockReason("rm -rf build", async () => false),
		/not granted/,
	);
});

test("allows an explicitly confirmed operation", async () => {
	assert.equal(
		await commandBlockReason("rm -rf build", async () => true),
		undefined,
	);
});

test("ordinary commands remain allowed", async () => {
	assert.equal(await commandBlockReason("go test ./..."), undefined);
});
