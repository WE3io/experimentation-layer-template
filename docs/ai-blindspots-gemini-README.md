# Gemini CLI Implementation

AI Blindspots principles translated for Gemini CLI. Canonical source: [ai-blindspots/](../../ai-blindspots/) in this repo.

## Setup

1. Copy this folder into your project root, or copy the contents into an existing project.
2. Ensure `GEMINI.md` is at project root.
3. Ensure `.agent/rules/` contains the rule files.

## Structure

```
implementations/gemini/
├── GEMINI.md
├── .agent/
│   └── rules/
│       ├── security.md
│       ├── debugging.md
│       ├── context-management.md
│       └── testing.md
├── docs/
│   └── articles/         # Bundled AI Blindspots articles (prompt-injection, debugging-blindspot)
└── README.md
```

## Usage

- **GEMINI.md** — Core principles at project root.
- **.agent/rules/** — Modular rules (security, debugging, context-management, testing). Hierarchy: Project > Workspace > User.

## Translation

Principles translated from canonical rules. See [ai-blindspots/TOOL_TRANSLATION_GUIDE.md](../../ai-blindspots/TOOL_TRANSLATION_GUIDE.md).

## Bundled Docs

`docs/articles/` contains bundled AI Blindspots articles for offline/standalone use. Source: `ai-blindspots/` in this repo; sync via `scripts/sync-bundled-docs.py`. For latest: [AI Blindspots](https://ezyang.github.io/ai-blindspots/). Do not edit bundled copies; they are overwritten by sync.

## References

- [AI Blindspots](https://ezyang.github.io/ai-blindspots/)
- [ai-blindspots/](../../ai-blindspots/) — Canonical rules, articles, QUICK_REFERENCE
