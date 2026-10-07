import { tool } from "@opencode-ai/plugin"
import { spawnSync } from "node:child_process"
import path from "node:path"

export default tool({
  description:
    "Run project verifications: Lua syntax, sprite-sheet validation, and the game logic/smoke harnesses.",
  args: {
    target: tool.schema
      .enum(["all", "syntax", "sprites", "logic", "smoke"])
      .optional()
      .describe("Which check to run (default: all)"),
  },
  async execute(args, context) {
    const target = args.target ?? "all"
    const script = path.join(context.worktree, "scripts", "verify.py")

    const proc = spawnSync("python3", [script, target], {
      cwd: context.worktree,
      encoding: "utf8",
    })

    if (proc.error) {
      return {
        title: `verify: ${target}`,
        output: `Failed to run verifier: ${proc.error.message}`,
        metadata: { exitCode: 1, target },
      }
    }

    const output = `${proc.stdout ?? ""}${proc.stderr ?? ""}`.trim()
    return {
      title: `verify: ${target}`,
      output: output || "(no output)",
      metadata: { exitCode: proc.status ?? 1, target },
    }
  },
})
