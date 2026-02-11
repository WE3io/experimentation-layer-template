# Scientific Debugging Method

Systematic debugging over guesswork. Demand root cause before fixes.

## Method

### 1. OBSERVE

- Actual vs. expected behavior?
- Error messages and logs?
- When does it occur?
- Can the issue be reproduced?

### 2. HYPOTHESIZE

- List 2–3 most likely causes.
- Rank by probability.
- Use "Five Whys" to trace root cause.

### 3. TEST

- How to verify each hypothesis?
- Add instrumentation before making changes.
- Run the test.

### 4. FIX

- Address root cause, not symptom.
- Minimal, targeted fixes over large rewrites.
- Verify fix works.
- Check for similar issues elsewhere.

## Avoid

- Shotgun fixes without understanding cause.
- Multiple changes at once.
- Fixing symptoms instead of root cause.

## Reference

See: AI Blindspots — [Debugging Blindspot](../docs/articles/debugging/debugging-blindspot.md)
