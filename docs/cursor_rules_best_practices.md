# Cursor Rules Best Practices

This guide outlines best practices for creating, organizing, and maintaining Cursor rules to maximize their effectiveness and maintainability.

---

## 1. Understanding Cursor Rules

Cursor rules are markdown files (`.mdc` format) that live in the `.cursor/rules` directory. They provide context, constraints, and guidelines to AI coding assistants to ensure consistent, high-quality code generation.

### Key Concepts
- **Rules are markdown files**: Written in standard markdown with code blocks
- **Location**: `.cursor/rules/` directory (can be nested in subdirectories)
- **Scoping**: Rules can be scoped to specific paths using patterns
- **Rule Types**: Always, Auto Attached, Agent Requested, Manual

---

## 2. Rule Types and When to Use Them

### Always Rules
**Use for**: Universal guidelines that should apply to all code generation.

**Characteristics**:
- Automatically included in every AI interaction
- Best for coding standards, security practices, architectural principles
- Keep concise to avoid token bloat

**Example Use Cases**:
- Code style guidelines (formatting, naming conventions)
- Security requirements (no hardcoded secrets, input validation)
- Architectural constraints (layering rules, dependency management)
- Language-specific best practices

**Best Practice**: Limit Always rules to 2-5 files covering the most critical universal constraints.

### Auto Attached Rules
**Use for**: Context that should be automatically included based on file paths or project structure.

**Characteristics**:
- Automatically attached when working in specific directories
- Use path patterns to scope rules to relevant contexts
- Reduces manual context management

**Example Use Cases**:
- Frontend-specific rules for `src/components/` or `src/pages/`
- Backend-specific rules for `api/` or `server/`
- Test-specific rules for `**/test/**` or `**/__tests__/**`
- Domain-specific rules for feature directories

**Best Practice**: Create Auto Attached rules for major subsystems or domains.

### Agent Requested Rules
**Use for**: Detailed documentation that the AI can fetch when needed.

**Characteristics**:
- Only included when the AI determines they're relevant
- Best for comprehensive documentation, API references, complex patterns
- Can be more verbose since they're not always loaded

**Example Use Cases**:
- API documentation and usage patterns
- Complex architectural decision records
- Detailed domain models and business rules
- Framework-specific patterns and conventions

**Best Practice**: Use for comprehensive reference material that doesn't need to be in every context.

### Manual Rules
**Use for**: Rules you explicitly reference with `@rule-name` in prompts.

**Characteristics**:
- Only included when explicitly mentioned
- Useful for optional or specialized guidelines
- Good for experimental or evolving practices

**Example Use Cases**:
- Experimental patterns or approaches
- Optional code quality improvements
- Specialized workflows for specific scenarios
- Documentation that's rarely needed

**Best Practice**: Use sparingly for truly optional or experimental content.

---

## 3. Organizing Rules

### Directory Structure

```
.cursor/
  rules/
    always/
      coding-standards.mdc
      security.mdc
      architecture.mdc
    auto-attached/
      frontend/
        react-patterns.mdc
        styling.mdc
      backend/
        api-conventions.mdc
        database.mdc
      tests/
        test-patterns.mdc
    agent-requested/
      api-reference.mdc
      domain-models.mdc
      architecture-decisions.mdc
    manual/
      experimental-patterns.mdc
```

### Organization Principles

1. **Group by Concern**: Organize rules by domain, layer, or concern
2. **Use Descriptive Names**: File names should clearly indicate content
3. **Keep Files Focused**: One file per major topic or concern
4. **Nest When Appropriate**: Use subdirectories for major subsystems
5. **Avoid Deep Nesting**: Keep directory depth reasonable (2-3 levels max)

---

## 4. Writing Effective Rules

### Structure Your Rules

```markdown
# Rule Title

Brief description of what this rule covers and why it matters.

## Scope
When and where this rule applies (if not universal).

## Guidelines

### Do's
- Clear positive guidance
- Specific examples

### Don'ts
- Clear negative guidance
- Anti-patterns to avoid

## Examples

### Good Example
```language
// Example of correct usage
```

### Bad Example
```language
// Example of incorrect usage
```

## Rationale
Why this rule exists and what problems it solves.
```

### Writing Principles

1. **Be Specific**: Avoid vague guidance; provide concrete examples
2. **Show, Don't Just Tell**: Include code examples for both correct and incorrect patterns
3. **Explain Why**: Help developers understand the rationale
4. **Keep It Actionable**: Focus on what to do, not just what to avoid
5. **Update Regularly**: Rules should evolve with your codebase and practices

### Code Examples in Rules

- Use proper code blocks with language tags
- Include both positive and negative examples
- Keep examples realistic and relevant
- Update examples when patterns change

---

## 5. Scoping Rules with Path Patterns

Use path patterns to scope rules to specific directories or file types.

### Common Patterns

- `**/*.tsx` - All TypeScript React files
- `src/components/**` - All files in components directory
- `**/test/**` - All test files
- `api/**/*.ts` - TypeScript files in api directory
- `!**/node_modules/**` - Exclude node_modules

### Best Practices for Scoping

1. **Be Specific**: Narrow scope to relevant contexts
2. **Test Patterns**: Verify patterns match intended files
3. **Document Scope**: Explain why a rule is scoped
4. **Avoid Overlap**: Ensure scoped rules don't conflict with Always rules

---

## 6. Common Patterns and Anti-Patterns

### ✅ Good Patterns

**Focused, Single-Purpose Rules**
```markdown
# React Component Patterns

Guidelines for writing React components in this project.
```

**Clear Examples**
```markdown
## Prefer Functional Components

### Good
```tsx
export const Button = ({ onClick, children }: ButtonProps) => {
  return <button onClick={onClick}>{children}</button>;
};
```

### Avoid
```tsx
export class Button extends React.Component {
  // Class components are discouraged
}
```
```

**Scoped Rules**
```markdown
# API Route Conventions

This rule applies to files matching: `api/**/*.ts`

Guidelines for creating API routes...
```

### ❌ Anti-Patterns

**Overly Broad Rules**
```markdown
# Everything About Everything

This rule covers:
- Frontend patterns
- Backend patterns
- Database patterns
- Testing patterns
- Deployment patterns
...
```

**Vague Guidance**
```markdown
# Code Quality

Write good code. Avoid bad code.
```

**Conflicting Rules**
```markdown
# Rule 1: Always use classes
# Rule 2: Always use functions
```

**Outdated Examples**
```markdown
# Using jQuery

Always use jQuery for DOM manipulation...
```

---

## 7. Rule Maintenance

### Regular Review Cycle

1. **Monthly Review**: Check rules for relevance and accuracy
2. **After Major Changes**: Update rules when architecture or patterns change
3. **Team Feedback**: Incorporate feedback from developers using the rules
4. **Version Control**: Track rule changes in git with clear commit messages

### Signs Rules Need Updates

- AI consistently generates code that violates rules
- Developers frequently override or ignore rule guidance
- Rules reference deprecated patterns or libraries
- New patterns emerge that aren't covered
- Rules become too long or complex

### Deprecation Strategy

1. Mark deprecated rules clearly
2. Provide migration guidance
3. Set a timeline for removal
4. Update related rules

---

## 8. Integration with Development Workflow

### Onboarding

- Include rule review in onboarding process
- Explain how rules are organized
- Show examples of how rules guide AI assistance

### Code Reviews

- Reference rules when reviewing AI-generated code
- Update rules based on review findings
- Use rules as a shared standard

### Team Collaboration

- Discuss rule changes in team meetings
- Document rule decisions and rationale
- Encourage team members to propose improvements

---

## 9. Measuring Rule Effectiveness

### Indicators of Effective Rules

- Consistent code style across AI-generated code
- Fewer review iterations needed
- Reduced need for manual corrections
- Positive developer feedback

### Indicators of Ineffective Rules

- AI frequently generates code that violates rules
- Rules are too verbose and slow down AI
- Rules conflict with actual codebase patterns
- Developers ignore or work around rules

### Iteration Process

1. Monitor AI-generated code quality
2. Collect feedback from developers
3. Identify gaps or conflicts
4. Update rules incrementally
5. Measure improvement

---

## 10. Advanced Strategies

### Rule Hierarchies

Create rule hierarchies where general rules are supplemented by specific ones:
- Base rules in `always/`
- Specific rules in `auto-attached/` for subsystems
- Detailed rules in `agent-requested/` for complex topics

### Rule Templates

Create templates for common rule types:
- Component patterns
- API conventions
- Test patterns
- Error handling

### Rule Documentation

Maintain a `README.md` in `.cursor/rules/` that:
- Explains rule organization
- Lists all rules and their purposes
- Provides guidance on adding new rules
- Links to related documentation

---

## 11. Security Considerations

### Sensitive Information

- **Never** include secrets, API keys, or credentials in rules
- Avoid hardcoded examples with real credentials
- Use placeholders and environment variable patterns

### Input Validation

- Include rules about input validation and sanitization
- Specify security requirements for user-facing code
- Document authentication and authorization patterns

---

## 12. Summary Checklist

When creating or updating Cursor rules:

- [ ] Rule has a clear, single purpose
- [ ] Rule type (Always/Auto Attached/Agent Requested/Manual) is appropriate
- [ ] Rule is scoped correctly with path patterns if needed
- [ ] Rule includes concrete examples (good and bad)
- [ ] Rule explains the rationale
- [ ] Rule doesn't conflict with other rules
- [ ] Rule is up-to-date with current patterns
- [ ] Rule is appropriately sized (not too verbose, not too brief)
- [ ] Rule follows the project's markdown style
- [ ] Rule is documented in the rules README

---

## 13. Resources and Further Reading

- Cursor Rules Documentation: [Official Cursor docs]
- Markdown Guide: [CommonMark Spec]
- Your Project's ACA Usage Guide: `docs/aca_usage_guide.md`

---

## Notes

Cursor rules are a powerful tool for maintaining code quality and consistency. Like any tool, they require thoughtful design, regular maintenance, and team buy-in to be effective. Start small, iterate based on feedback, and evolve your rules as your project and team grow.

