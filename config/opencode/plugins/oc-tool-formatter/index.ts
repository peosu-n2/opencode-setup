import type { Plugin, Hooks } from "@opencode-ai/plugin"

// Tools whose output should be wrapped in a fenced code block.
// Skip "task" (subagent prose), "todowrite"/"todoread" (already structured),
// "skill" (variable shape), MCP tools (they handle their own formatting).
const WRAP_TOOLS = new Set(["bash", "read", "glob", "grep", "edit", "write", "webfetch"])

// Language hint per tool — drives syntax highlighting where the TUI supports it.
const LANG_HINT: Record<string, string> = {
  bash: "bash",
  read: "",       // file contents — leave unhinted (could be anything)
  glob: "",       // path list
  grep: "",       // grep output, mixed
  edit: "diff",   // edit results often look diff-like
  write: "",      // confirmation message
  webfetch: "",   // page text
}

export const ToolOutputFormatter: Plugin = async () => {
  return {
    "tool.execute.after": async (input, output) => {
      const tool = input.tool
      if (!WRAP_TOOLS.has(tool)) return

      const text = output.output
      if (typeof text !== "string" || text.length === 0) return

      // Don't double-wrap if something else already fenced it.
      if (text.startsWith("```")) return

      const hint = LANG_HINT[tool] ?? ""
      const fence = "```" + hint
      // Indent each line by 2 spaces so even inside the code block the
      // content feels subordinate to surrounding agent prose.
      const indented = text.split("\n").map((l) => "  " + l).join("\n")
      output.output = `${fence}\n${indented}\n\`\`\``
    },
  } as Hooks
}

export default ToolOutputFormatter
