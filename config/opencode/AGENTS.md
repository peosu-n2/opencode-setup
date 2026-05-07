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
Available: `dasel`, `jq`, `yq`, `sd`, `rg`, `fd`, `bat`, `xh`, `curl`, `tidy`. Add any project-specific custom utilities to `tool-patterns.md` and reference them on demand.

## Common Mistake Prevention Rules
1. **NEVER edit JSON/YAML files manually** - Use `jq` or `yq` commands
2. **NEVER use bare `python`/`python3`** - Activate the project venv first (or use `uv run` / `poetry run` / similar wrapper)
3. **ALWAYS check Docker status** before running Docker commands
4. **ALWAYS preview Git changes** before committing
5. **USE project-specific commands** from `package.json`/`pyproject.toml`
6. **NEVER use `sed` for text replacement** - Use `sd` (safe and intuitive)
7. **NEVER use `grep -r` for code search** - Use `rg` (fast and respects .gitignore)
8. **NEVER use `find` for file finding** - Use `fd` (simpler syntax, faster)
9. **NEVER use `cat` for file viewing** - Use `bat` (syntax highlighting, line numbers)
10. **CONSIDER `dasel` for multi-format configs** - Use jq for JSON, yq for YAML, dasel for cross-format operations

## Python environment rule
- **ALWAYS** install/run Python through the project venv or a project-aware wrapper, never bare `python`/`pip`.
- Use `uv run` / `poetry run` / a project-specific wrapper, or `source .venv/bin/activate` first.
- Goal: scratch installs go into a known env, not the system Python and not ad-hoc temp venvs.


## Project Entry Checklist
When entering a new project directory:
1. Check `tool-patterns.md` for available tools and patterns
2. Detect project type: `package.json` (Node), `pyproject.toml` (Python), etc.
3. Use project-specific commands (e.g., `npm test` for Node, `pytest` for Python)
4. **Check for project-specific agent configuration** (e.g., `PROJECT_AGENT.md`, `.opencode/` directory) for deployment and environment guidelines


---

## Model-Specific Rules

### When using V4 Pro thinking (plan, reviewer, debug)
- Chain-of-thought stays internal — do **not** include `<think>` blocks or raw reasoning in the final answer.
- `temperature` is ignored when thinking is on; don't bother tuning it.
- Prefer **one concrete plan** over exploring multiple branches in the output.
- For file edits, hand off to a non-thinking agent — reasoning agents should produce specs, not patches.

### When using V4 Flash non-thinking (build, ship, researcher)
- `temperature: 0` for code, tests, refactors. Raise only for brainstorming.
- Supports tool/function calling — use tools eagerly instead of guessing.

### When using V4 Pro non-thinking (build-pro)
- `temperature: 0.3` — slight variability helps strategic reasoning explore alternatives.
- Do the architectural thinking yourself; delegate mechanical edits to the executor (`build`).

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
