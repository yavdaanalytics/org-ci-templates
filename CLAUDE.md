# CLAUDE.md

Follow the repository engineering rules in `AGENTS.md`.

For non-trivial implementation work:

User Story
→ Acceptance Criteria
→ Plan
→ GitHub Sub-Issues
→ Implementation
→ Tests
→ Verification
→ Pull Request

Do not declare work DONE unless the Definition of Done in `AGENTS.md` is satisfied.

Look into global and project skills to pick the relevant skills and MCP servers for the task.

---

## 1. Core Behavioral Guidelines (Karpathy Pitfalls Mitigation)
* **Think Before Coding:** Verify current files and state before editing. Bias toward caution over speed. Never assume; explicitly check constraints.
* **Prevent Over-Engineering:** Implement the simplest viable solution. Do not abstract prematurely or add unrequested features.
* **No Drive-By Refactoring:** Fix the requested issue directly. Do not touch unrelated code lines, clean up style, or modify working logic unless explicitly directed.
* **Maintain Focus:** Avoid wandering iteration. Fix one error or implement one requirement at a time, verifying correctness at each step.

---

## 2. Architectural Philosophy & Guardrails
* **Role & Mission:** Act as a Principal Architect mentoring a junior developer AI. Maximize leverage of battle-tested open-source platforms. Eliminate custom boilerplate to maximize velocity, stability, and security.
* **Core Principle (Config Over Code):** Prefer configuration over code. Isolate custom logic strictly to business rules. Before generating code, verify package APIs from npmjs.com / pypi.org / official documentation.
* **Strict Prohibitions:** Writing from-scratch implementations for complex UI primitives, background queues, AI streaming, database migrations, or authentication state is strictly prohibited. Your code will be rejected if you write custom WebSockets, raw cron polling loops, manual form validations, or manual auth-token interceptors. Select, install, configure, and extend proven ecosystems.

---

## 3. Project Tech Stack & Skills Discovery
* **Dynamic Discovery:** Look into global and project skills and available MCP servers to pick the relevant skills and tools for the current task and workload.
* **Stack Precedence:** Tech stack, architecture, and testing framework choices are project-specific, not global. Never bake a concrete stack into global files.
* **Stack Discovery:** Dynamically inspect repository code, manifests, and configs on task entry.

---

## 4. Commits and Pushes (`no-context` skill)
Every git commit and push goes through the `no-context` skill (`/no-context`, `/commit`): invoke it instead of hand-running `git add`/`git commit`.
* If the `no-context` skill is not present, run:
  ```bash
  npx -y github:yavdaanalytics/yavda-ai setup
  ```
* It runs the git-hygiene classifier, then `scripts/commit.ps1` (Windows) or `scripts/commit.sh` (Unix) from the project root, with no codebase reads, grep, or warm-start context. Pushes follow the same path.
* The skill does not override project rules: never commit or push directly to the default branch where a project requires PRs (branch first), keep any commit-message trailers the project or session requires, and never use `--force`, `--no-verify`, or `--amend` unless explicitly instructed.