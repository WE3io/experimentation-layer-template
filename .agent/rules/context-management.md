# Context Management

## Session Restarts

Long conversations (>20–30 messages) accumulate errors and misconceptions. Early mistakes compound.

**When to suggest restart:**

- Going in circles
- Switching to a different subsystem
- Early assumption was wrong
- Over 30 messages without clear progress

**Restart template:**

```
Previous session summary:
- Problem: [clear description]
- Tried: [list approaches]
- Learned: [key insights]
- Root cause: [if known]

Current state: [files, errors, expected behavior]
Next approach: [fresh perspective]
```

## Checkpointing

- Summarize progress every 10–15 messages.
- Verify assumptions early.
- Correct misconceptions immediately.
- Track what's established vs. unknown.

## File Size

- Keep files <64KB for context management.
- Split large files before major changes.
- Monitor file sizes during development.
