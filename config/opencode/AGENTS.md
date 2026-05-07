# Tool Awareness & Patterns System

## Core Configuration
- MY CONFIG IS LOCATED AT: `~/.config/opencode/`
- MY PROJECT SKILLS ARE AT: `.opencode/skills/`
- TOOL PATTERNS REFERENCE: `~/.config/opencode/tool-patterns.md`

## Tool Awareness Protocol
**BEFORE starting work on any task:**
1. **Check available tools** using quick reference in `tool-patterns.md`
2. **Use patterns, not rediscovery** - follow established patterns for common operations
3. **Prevent common mistakes** - use jq/yq instead of manual JSON/YAML edits

## Essential Tools (inventory)
Available: `dasel`, `jq`, `yq`, `sd`, `rg`, `fd`, `bat`, `xh`, `curl`, `tidy`, `python-project`. Healthcare: `cq`, `dq`, `ms`, `mt`. Office: `word2txt`, `docx-search`, `excel2csv`. Usage examples and full custom-utility list in `tool-patterns.md` — read it on demand, not preemptively.

## Common Mistake Prevention Rules
1. **NEVER edit JSON/YAML files manually** - Use `jq` or `yq` commands
2. **NEVER use `python` or `python3` directly** - Use `python-project` for correct environment
3. **ALWAYS check Docker status** before running Docker commands
4. **ALWAYS preview Git changes** before committing
5. **USE project-specific commands** from `package.json`/`pyproject.toml`
6. **NEVER use `sed` for text replacement** - Use `sd` (safe and intuitive)
7. **NEVER use `grep -r` for code search** - Use `rg` (fast and respects .gitignore)
8. **NEVER use `find` for file finding** - Use `fd` (simpler syntax, faster)
9. **NEVER use `cat` for file viewing** - Use `bat` (syntax highlighting, line numbers)
10. **CONSIDER `dasel` for multi-format configs** - Use jq for JSON, yq for YAML, dasel for cross-format operations

## Python install rule (load-bearing)
- **ALWAYS** install Python packages with `python-project -m pip install <pkg>` — never bare `pip install` or `pip3 install`.
- `python-project` resolves to the correct env per `~/.config/opencode/python-environments.json`. The default for unmapped directories is `gn` (general env: pandas, openpyxl, python-docx). Mapped paths (e.g., `/some-project/sub*` → `sub-env`) use their project env.
- Same rule for running Python: `python-project script.py` and `python-project -m pytest`, never bare `python`/`python3`.
- This means scratch installs land in `gn` — a known, shared env — instead of polluting the system Python or creating ad-hoc venvs. Re-run `detect-python-env --json` if you're unsure which env is active.


## Project Entry Checklist
When entering a new project directory:
1. Check `tool-patterns.md` for available tools and patterns
2. Detect project type: `package.json` (Node), `pyproject.toml` (Python), etc.
3. Use project-specific commands (e.g., `npm test` for Node, `pytest` for Python)
4. Reference healthcare utilities if in healthcare project
5. **Check for project-specific agent configuration** (e.g., `PROJECT_AGENT.md`, `.opencode/` directory) for deployment and environment guidelines


---

## Model-Specific Rules

### When using `deepseek-reasoner` (plan, reviewer)
- The chain-of-thought is internal — do **not** include `<think>` blocks or raw reasoning in the final answer.
- `temperature` is ignored by this model; don't bother tuning it.
- Prefer **one concrete plan** over exploring multiple branches.
- For any file edit, hand off to the `build` agent — reasoner is read-only by config.
- Budget: 64K input, up to 64K output. For large codebases, summarize aggressively before quoting.

### When using `deepseek-chat` (build, researcher)
- `temperature: 0` for code, tests, refactors. Raise only for brainstorming.
- Output cap is 8K tokens max — for large generations, split into multiple turns.
- Supports tool/function calling — use tools eagerly instead of guessing.

### Agent routing
- `/agent build` (default) → implementation, edits, running tests. Fast loop on `deepseek-chat`. Auto-invokes `plan` subagent for complex tasks.
- `/agent ship` → V4→R→V4 loop: optional plan → implement → reviewer audit. Use for migrations, auth, payments, prod data.
- `/agent plan` → architectural thinking, migration design, API design. Writes to `.opencode/plans/<date>-<slug>.md`. `mode: all` — also callable as a subagent by build/ship.
- `/agent debug` → hard bugs, mystery failures. Hypothesis-ranking before fix. Writes to `.opencode/debug/<date>-<slug>.md`. `mode: all` — also subagent-callable.
- `reviewer` subagent → diff audit, invoked by ship or via Task.
- `researcher` subagent → codebase Q&A without burning main context.

### When to pick which
- Greenfield feature, clear spec → `build`.
- Greenfield feature, fuzzy spec → `build` (it'll auto-delegate to `plan`) — or `/agent plan` directly if you want the plan in chat without auto-implement.
- Touching risky surfaces (auth, money, migrations, deletes) → `ship`.
- Test fails and you don't know why → `/agent debug`, then `build` to apply the fix.

### Saved-plan handoff
Plans land at `.opencode/plans/<YYYY-MM-DD>-<slug>.md`, debug analyses at `.opencode/debug/<YYYY-MM-DD>-<slug>.md`. To resume work later: `/agent build implement the plan in .opencode/plans/<filename>`.

---

**IMPORTANT**: Follow patterns from `tool-patterns.md` to avoid rediscovery loops and common mistakes.
