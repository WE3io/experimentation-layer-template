# Cursor Rules Documentation

This directory contains rules and guidelines for AI coding assistants in this project.

## Organization

### Always Rules (`always/`)
Rules that are automatically included in every AI interaction:
- `core-principles.mdc` - Core principles and task complexity assessment
- `workflows.mdc` - Task-specific workflows and patterns
- `guardrails.mdc` - Constraints, quality checks, and security requirements

### Agent Requested Rules (`agent-requested/`)
Detailed reference material that AI can fetch when needed:
- `review-checklist.mdc` - Comprehensive self-review checklist

## Rule Types

- **Always**: Automatically included in every context
- **Auto Attached**: Automatically attached based on file paths (none currently)
- **Agent Requested**: Fetched by AI when relevant
- **Manual**: Referenced explicitly with `@rule-name` (none currently)

## Adding New Rules

1. Determine the appropriate rule type and directory
2. Follow the structure and examples in existing rules
3. Include code examples (good and bad patterns)
4. Add scope declarations if not universal
5. Update this README with the new rule

## Translation Validation

When adding or updating rules, use [cursor-translation.md](https://github.com/WE3io/cursor-rules-template/blob/main/ai-blindspots/checklists/cursor-translation.md) to verify intent preservation and mechanism adaptation. (Monorepo: `../../../../ai-blindspots/checklists/cursor-translation.md`)

## Related Documentation

Required (expected in this template):
- `../../docs/aca_usage_guide.md` - Full AI Coding Assistant Usage Guide
- `../../docs/cursor_rules_best_practices.md` - Best practices for creating rules

Optional canonical references:
- **Monorepo:** Use `../../../../ai-blindspots/QUICK_REFERENCE.md` and `../../../../ai-blindspots/rules/ai-coding-assistant-rules.md` when this folder lives in the full ai-assistant-rules repo.
- **Standalone:** Use [QUICK_REFERENCE.md](https://github.com/WE3io/cursor-rules-template/blob/main/ai-blindspots/QUICK_REFERENCE.md) and [ai-coding-assistant-rules.md](https://github.com/WE3io/cursor-rules-template/blob/main/ai-blindspots/rules/ai-coding-assistant-rules.md) from the upstream repo, or copy those files into your project.

## Maintenance

Rules should be reviewed monthly and updated when:
- Architecture or patterns change
- New best practices emerge
- Team feedback indicates improvements needed
- Rules become too verbose or complex
