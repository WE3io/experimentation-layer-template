# AI Blindspots — Core Principles

Behavioral guidelines for AI-assisted development. Based on [AI Blindspots](https://ezyang.github.io/ai-blindspots/). Canonical source: `ai-blindspots/` in this repo.

---

## Core Principles

### Problem-Solving

- **Stop digging:** Pivot approach after 3 unsuccessful iterations. Do not persist-and-fail.
- **Root cause first:** Demand reproduction steps and root cause analysis before proposing fixes. Debug systematically: observe → hypothesize → test → fix.
- **Context pollution:** Sessions degrade after ~20–30 messages without progress. Suggest restart with: problem summary, what didn't work, alternative approach.

### Requirements and Communication

- **Specify requirements, not solutions:** Focus on constraints and goals. Unspecified requirements default to training assumptions.
- **Communicate uncertainty:** State confidence level for non-trivial recommendations. List alternatives and trade-offs.
- **Checkpoint progress:** Summarize periodically; verify assumptions early.

### Change Management

- **Decompose changes:** Break into focused, reviewable steps. Single responsibility per change.
- **Preparatory refactoring:** Make the change easy, then make the easy change.
- **Walking skeleton:** Get end-to-end basic version working before optimization.

### AI Strengths and Limitations

- **Leverage strengths:** Code generation, boilerplate, mechanical refactoring.
- **Acknowledge weaknesses:** Debugging non-obvious bugs, root cause identification, security implications.
- **Verify critical items:** LLMs sound confident when wrong.
- **Knowledge limits:** Verify framework/API details against primary docs when unsure.

### Type Safety and Execution Hygiene

- **Type systems first:** Prefer static types and strict compiler settings where available.
- **Static-types workflow:** Run type checks before tests and before finalizing structural refactors.
- **Stateless commands:** Make each shell command independently runnable; avoid hidden shell-state dependencies.

---

## Project Context

- Work in small, reviewable increments.
- Prioritize correctness and simplicity over cleverness.
- Black box testing: test behavior, not implementation.
- Keep files <64KB for context management.
- Security review for sensitive code.
