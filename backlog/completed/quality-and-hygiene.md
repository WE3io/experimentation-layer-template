# Quality & Hygiene: CI/CD and TODO Resolution

## Outcome

Established CI/CD workflows for automated linting and testing, and the resolution of all remaining `TODO` placeholders in core documentation and scripts to ensure the repository is in a "clean" state.

## Constraints & References

- **CI/CD:** Use GitHub Actions (`.github/workflows/`).
- **Linting:** Must cover Python (e.g., `ruff`) and Markdown (e.g., `markdownlint`).
- **Testing:** Must run the test suites for services and training scripts.
- **Repository Standards:** Follows `GEMINI.md` principles for execution hygiene.

## Acceptance Checks

- [ ] `.github/workflows/ci.yml` is created and configured to run on push/PR.
- [ ] Python linter (e.g., ruff) configuration is added (e.g., `pyproject.toml`).
- [ ] CI pipeline successfully runs linting and all discovered unit tests.
- [ ] All `TODO` comments in `README.md` are resolved or converted to backlog items.
- [ ] All `TODO` comments in `training/train_planner.py` are addressed.

## Explicit Non-Goals

- Implementation of CD (Continuous Deployment) pipelines.
- Achieving 100% test coverage for all code paths.
- Resolving `TODO`s that require significant new feature development (these should be new backlog items).
