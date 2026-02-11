# AI Coding Assistant (ACA) Usage Guide

This guide provides a practical, evidence-informed framework to help developers use AI Coding Assistants effectively, safely, and productively within day-to-day engineering work.

It combines task fit, workflows, context strategies, guardrails, and evaluation loops into a single coherent approach suitable for individual developers or teams.

---

## 1. Purpose of This Guide
AI Coding Assistants can accelerate development, improve documentation and tests, and reduce repetitive work. They can also introduce subtle bugs, increase review load, or cause architectural drift when used without clear constraints.

This guide outlines when and how to use ACAs, how to provide context, how to review output, and how to evaluate their real impact.

---

## 2. Task × Complexity Matrix
ACAs perform very differently depending on the nature of the task and its scope. Use the following matrix to decide how much to rely on the assistant.

### 2.1 Task Categories
- **Boilerplate & Glue Code** – simple mappings, adapters, DTOs, API wrappers.
- **Tests & Documentation** – unit tests, integration tests, docstrings, READMEs.
- **Local Feature Implementation** – changes contained within a few files.
- **Complex Feature Work** – multi-file, multi-service or cross-module changes.
- **Bug Fixing & Debugging** – reasoning about failures and proposing patches.
- **Refactoring & Clean-up** – improving structure without changing behaviour.
- **Architecture & Design** – module boundaries, system structure.
- **Exploratory Spikes** – learning APIs or exploring new tools.

### 2.2 Complexity Levels
- **L1 – Local**: Limited to one or two functions/files.
- **L2 – Module**: Involves a whole feature or subsystem.
- **L3 – Cross-System**: Affects architecture, multiple services, or shared contracts.

### 2.3 Fit Summary
- **Strong Fit**: Boilerplate (L1–L2), tests & docs (L1–L2), exploratory spikes (L1–L2).
- **Conditional Fit**: Local features (L1–L2), refactoring (L1–L2), debugging (L1–L2).
- **High Risk**: Complex feature work (L3), architectural design (L3), large refactors (L3).

---

## 3. Interaction Workflows
Use different workflows depending on the type of task.

### 3.1 Boilerplate & Glue Code
1. Provide the function signature, types, constraints, and examples.
2. Ask for a brief plan before code.
3. Generate code in small pieces.
4. Request tests immediately.
5. Review for correctness and simplicity.

### 3.2 Tests & Documentation
1. Provide source code and expected behaviour.
2. Ask for tests covering success, failure, and edge cases.
3. Review tests for accuracy and clarity.
4. Use ACA to draft documentation, then refine.

### 3.3 Local Feature Implementation
1. Write clear acceptance criteria and constraints.
2. Ask ACA for an implementation plan.
3. Implement in small increments.
4. Generate tests per increment.
5. Review explanations of complex logic.

### 3.4 Refactoring
1. Specify the goal and behavioural constraints.
2. Ask for a refactor plan first.
3. Apply changes one step at a time.
4. Regenerate or update tests.
5. Compare behaviour with the original.

### 3.5 Debugging
1. Provide failing code, errors, and minimal examples.
2. Ask ACA to list possible root causes.
3. Request a minimal fix and explanation.
4. Add new tests to prevent recurrence.

---

## 4. Context Strategy
ACAs produce higher-quality output when given targeted and structured context.

### 4.1 Types of Context
- **Immediate Code Context**: Relevant functions, classes, or files.
- **Local Design Context**: Module purpose and invariants.
- **Domain Rules**: Business constraints or domain concepts.
- **Non-Functional Constraints**: Performance, security, reliability, style rules.

### 4.2 Context Bundles
Use predefined bundles:

**New Function:** Provide the file, function signature, conventions, and constraints.

**Modifying Behaviour:** Provide old code, tests, desired changes, and invariants.

**Refactoring:** Provide the code and explain the motivation and constraints.

**Debugging:** Provide failing tests, logs, and recent changes.

---

## 5. Guardrails
Guardrails reduce the risk of drift, errors, and over-engineering.

### 5.1 Prompt-Level Constraints
- "Only modify the function X; do not touch other code."
- "Do not introduce new dependencies or abstractions."
- "State all assumptions before generating code."
- "Prefer small incremental changes."

### 5.2 Behavioural Guardrails
- Do not accept large diffs without explanation.
- Work in small, reviewable increments.
- Ask ACA to explain differences between versions.
- Require it to list edge cases and risks.

### 5.3 Tooling Guardrails
- Run automated tests after each change.
- Use static analysis and linters.
- Use security scanners where relevant.

---

## 6. Failure-Mode Checklist
Use this checklist during review.

### 6.1 Logic Errors
Check for missing edge cases or incorrect logic; ask ACA to identify risks.

### 6.2 Performance Issues
Ask the ACA to provide complexity analysis; review for hot-path inefficiencies.

### 6.3 Security Issues
Ensure untrusted inputs are validated; avoid secrets in code; run security scanning.

### 6.4 Architectural Drift
Verify layering constraints, avoid new abstractions unless required.

### 6.5 Over-Engineering
Prefer simple, readable code; ask ACA to simplify if necessary.

### 6.6 API Misuse
Cross-check usage patterns against documentation.

---

## 7. Evaluation Loop
Determine where ACAs help or hinder.

### 7.1 Individual Developer Loop
1. Pick 2–3 recurring task types.
2. Establish a baseline without ACA.
3. Perform similar tasks with ACA.
4. Track time, iterations, defects, and mental load.
5. Decide where ACA accelerates, where it harms, and where it should be limited.

### 7.2 Team-Level Loop
1. Tag PRs significantly assisted by ACA.
2. Track review complexity, defects, and cycle time.
3. Discuss patterns in retros.
4. Promote, constrain, or experiment with ACA use in specific task types.

---

## 8. Integrating This Guide into Development Practice
- Add this guide to onboarding materials.
- Encourage teams to adapt context bundles and workflows to their stack.
- Periodically update the matrix and guardrails as tools improve.
- Use evaluation loops to refine or relax constraints.

---

## 9. Summary
Responsible, context-aware use of ACAs can meaningfully improve productivity, reduce repetitive work, and boost quality, particularly for local, well-defined tasks. The key is disciplined workflows, clear constraints, strong review practices, and continuous evaluation.

This guide provides the structure and practices to achieve consistent, reliable value from AI coding assistants across a variety of development contexts.

