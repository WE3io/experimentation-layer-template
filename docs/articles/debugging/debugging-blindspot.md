# The Debugging Blindspot

*Created: February 2026*

## The Blindspot

LLMs are significantly better at generating new code than debugging existing code. They tend to treat symptoms rather than identifying root causes, make changes without fully understanding the problem, and struggle with non-obvious bugs.

## Why It Happens

**Generation vs. Comprehension Asymmetry:**
- Trained primarily on writing code from scratch
- Less training on debugging existing code
- Pattern completion favors adding code over understanding bugs
- Debugging requires deeper causal reasoning

**Limited Execution Understanding:**
- LLMs see static code, not runtime behavior
- Can't observe actual program execution
- Don't experience the bug directly
- Infer behavior from code structure alone

**Symptom-Focused Thinking:**
- Error message → quick fix pattern matching
- Doesn't naturally ask "why did this happen?"
- Jumps to solutions before understanding cause
- Treats local symptoms without seeing system-wide issues

**No Hypothesis Testing:**
- Can't run experiments to test theories
- No interactive debugging experience
- Can't set breakpoints or inspect variables
- Relies on user to report observations

## Impact

**Surface-Level Fixes:**
- Fixes symptom, not root cause
- Bug reappears in slightly different form
- Creates technical debt
- Masks underlying issues

**Shotgun Debugging:**
- Multiple random changes
- Not sure which change (if any) helped
- Hard to verify fix is correct
- May introduce new bugs

**Incomplete Understanding:**
- Doesn't fully grasp the bug's nature
- Misses edge cases and related issues
- Can't predict where else problem might occur
- Inadequate explanation of the fix

**Efficiency Loss:**
- Many iteration cycles
- Fixes that don't work
- Back-and-forth testing
- User doing most of the analytical work

## Mitigation Strategies

### 1. Demand Root Cause Analysis

**Before Accepting a Fix:**
```
❌ BAD:
User: "There's a bug where users get logged out randomly"
LLM: "Try adding this code to refresh the token..."
[Quick fix without understanding]

✅ GOOD:
User: "There's a bug where users get logged out randomly"
LLM: "Before suggesting a fix, help me understand the root cause:
      1. What triggers the logout? Time-based? Action-based?
      2. Any error messages?
      3. Does it happen for all users or specific ones?
      4. Recent code changes?
      5. What does application logs show?

      I want to understand WHY before suggesting HOW to fix."
```

### 2. Use Scientific Debugging Method

**Structure the Process:**
```markdown
## Debugging Protocol

1. OBSERVE
   - What is the actual behavior?
   - What is the expected behavior?
   - When does it happen? When doesn't it?
   - Any error messages or logs?

2. HYPOTHESIZE
   - What could cause this behavior?
   - List 2-3 most likely root causes
   - Rank by probability

3. TEST
   - How can we verify each hypothesis?
   - What experiment would confirm/reject it?
   - Run the test

4. ANALYZE
   - What did the test reveal?
   - Confirmed or rejected hypothesis?
   - What's the next hypothesis if rejected?

5. FIX
   - Only after root cause identified
   - Minimal change that addresses cause
   - Verify fix works
   - Check for similar issues elsewhere
```

### 3. Require Reproduction Steps

**Must Reproduce Before Fixing:**
```
User: "There's a crash when users submit the form"

LLM: "Before I propose a fix, let's reproduce it:
      1. Can you share the exact steps to trigger it?
      2. What data was submitted?
      3. What's the error message/stack trace?
      4. Does it happen every time?

      I'll review the code path for those steps."
```

Without reproduction, fixes are guesswork.

### 4. Use Debugging Tools, Not Code Changes

**Instrumentation Over Modification:**
```python
❌ BAD: Modify code and hope it fixes the bug

✅ GOOD: Add logging to understand what's happening
print(f"DEBUG: User state = {user.state}")
print(f"DEBUG: Token expiry = {token.expires_at}")
print(f"DEBUG: Current time = {datetime.now()}")

# Now we can see what's actually happening
```

**Then:**
- Understand the bug from logs
- Identify root cause
- Make minimal, targeted fix
- Remove debug logging

### 5. Ask "The Five Whys"

**Drill Down to Root Cause:**
```
Bug: "Website is slow"

Why? "Database queries are taking long"
Why? "Queries are fetching too much data"
Why? "No pagination on user list"
Why? "Recent refactor removed the LIMIT clause"
Why? "Refactor didn't have tests for pagination"

Root cause: Missing test coverage allowed regression.
Fix: 1) Add LIMIT clause, 2) Add pagination tests
```

### 6. Prefer Minimal Changes

**Surgical Fixes Over Rewrites:**
```
❌ BAD:
"This function is buggy. Let me rewrite the whole thing..."
[Rewrites 100 lines, potentially introducing new bugs]

✅ GOOD:
"The bug is in line 47 where we check null incorrectly.
 Changing: if (user.name)
 To: if (user.name !== undefined && user.name !== null)

 This fixes the specific null handling issue without
 changing other working logic."
```

## Examples

### Example 1: Symptom Treatment

**Bug Report:**
```
"Application crashes with 'Maximum call stack exceeded'"
```

**LLM (Symptom Fix):**
```javascript
❌ "Try increasing the stack size:
node --stack-size=2000 app.js"
```

**Problem:** Treats symptom (stack overflow) not cause (infinite recursion).

**Better Approach:**
```
LLM: "Maximum call stack exceeded typically means infinite recursion.
      Before changing stack size, let's find the recursive call:

      1. Can you share the stack trace?
      2. What operation triggers this?
      3. Let's examine the code path for recursive patterns

      I suspect there's a function calling itself without a proper base case."

[Investigates stack trace]

LLM: "Found it. In the permissions check:

function hasPermission(user, resource) {
  if (user.role === 'admin') return true;
  return hasPermission(user.parent, resource);  // ← Missing null check
}

When user.parent is null, this recurses infinitely.
Fix: Add null check before recursion."
```

### Example 2: Shotgun Debugging

**Bug:** "Form validation doesn't work"

**LLM (Shotgun Approach):**
```javascript
❌ "Try these changes:
// Change 1: Update validation library version
npm update validator

// Change 2: Add more validation rules
schema: {
  email: { required: true, email: true, minLength: 5 }
}

// Change 3: Change validation timing
validateOnBlur: true

// Change 4: Update form library
npm update react-hook-form
```

**Problem:** Multiple random changes. Don't know what fixes it (if anything).

**Better Approach:**
```
LLM: "Let's debug systematically:

Step 1: Verify validation is running
console.log('Validation called:', values)

[User reports: No log output]

LLM: "Validation isn't being called at all. Let's check:
      1. Is the form onSubmit handler connected?
      2. Is preventDefault() working?
      3. Is the validation function imported correctly?"

[User checks]

User: "Oh! The onSubmit prop has a typo: onSumbit"

LLM: "There's the root cause. Fix the typo:
      onSumbit → onSubmit

      One character typo, easily fixed with targeted debugging."
```

### Example 3: Missing Edge Cases

**Bug:** "Sorting doesn't work correctly"

**LLM (Incomplete Fix):**
```javascript
❌ "Change the sort function:
data.sort((a, b) => a.value - b.value)"
```

**Test reveals:** Works for numbers, breaks for strings.

**Problem:** LLM didn't ask what type of data, assumed numbers.

**Better Approach:**
```
LLM: "Before fixing the sort, I need to understand:
      1. What type of data are you sorting? (numbers/strings/dates/mixed)
      2. What's the current behavior vs expected?
      3. Can you share example data and expected order?

      This affects whether we use numeric sort, string sort,
      or custom comparison logic."

User: "Mixed data - sometimes numbers, sometimes strings"

LLM: "Ah, that requires careful handling:

function smartSort(a, b) {
  const aNum = Number(a.value);
  const bNum = Number(b.value);

  // Both are numbers
  if (!isNaN(aNum) && !isNaN(bNum)) {
    return aNum - bNum;
  }

  // At least one is string - use string comparison
  return String(a.value).localeCompare(String(b.value));
}

data.sort(smartSort)

This handles both numbers and strings correctly."
```

### Example 4: The Actual Bug Location

**Bug Report:** "Image upload doesn't work"

**LLM (Wrong Location):**
```javascript
❌ "Let's fix the frontend file upload:

// Add file type validation
<input
  type="file"
  accept="image/*"
  onChange={validateAndUpload}
/>
```

**User:** "Still doesn't work"

**LLM:** "Try updating the form encoding..."

**User:** "Still failing. Here's the error: 413 Payload Too Large"

**LLM:** "OH! The issue isn't in your frontend code at all.
The server is rejecting the upload due to size limits.
Fix needed in backend:

// Express server
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

Or configure nginx if you're using it.

The frontend code was fine. I should have asked for the
error message first before assuming frontend issue."
```

### Example 5: Systematic Success

**Bug:** "Users can see each other's data"

**Systematic Debugging:**
```
LLM: "This is a serious security issue. Let's debug methodically:

1. OBSERVE:
   - Can you give me an example of wrong data shown?
   - Is this happening for all users or specific ones?
   - When did this start?

User: "User Alice sees Bob's orders. Started after yesterday's deployment."

LLM: "2. HYPOTHESIZE:
   Most likely causes:
   a) Missing user ID filter in database query
   b) Session mixup (wrong user ID)
   c) Caching returning wrong user's data

   3. TEST:
   Can you check the actual database query being run?
   Add logging: console.log('Query:', query, 'UserID:', userId)"

User: [shows logs]
Query: "SELECT * FROM orders"
UserID: 123

LLM: "Found it! The query has no WHERE clause filtering by user ID.
Yesterday's deployment probably changed this query.

4. ROOT CAUSE:
   Query missing: WHERE user_id = ?

5. FIX:
   SELECT * FROM orders WHERE user_id = ?

   Also need to:
   - Add test for user data isolation
   - Audit other queries for same issue
   - Review yesterday's deployment for similar problems"
```

## Related Principles

- **Scientific Debugging** - Systematic hypothesis testing
- **Stop Digging** - Know when debugging approach isn't working
- **The Context Pollution Problem** - Long debugging sessions compound errors
- **Requirements, not Solutions** - Understand problem before solution

## Debugging Checklist

**Before Proposing a Fix:**

- [ ] Do we understand the root cause?
- [ ] Have we reproduced the bug?
- [ ] Do we know why it happens?
- [ ] Have we tested our hypothesis?
- [ ] Is this the minimal fix?
- [ ] Did we check for similar issues elsewhere?
- [ ] Do we have tests to prevent regression?

**Red Flags:**
- 🚩 Proposing fix without asking questions
- 🚩 Multiple simultaneous changes
- 🚩 "Try this and see if it works"
- 🚩 Rewriting large sections
- 🚩 No explanation of why fix works

**Green Flags:**
- ✅ Asks clarifying questions first
- ✅ Wants to see error messages/logs
- ✅ Proposes hypothesis before solution
- ✅ Suggests adding instrumentation
- ✅ Minimal, targeted changes
- ✅ Explains root cause clearly

## Current State (2026)

**Improvements:**
- Better code comprehension
- Some tool use for debugging (running code, checking logs)
- Improved ability to read stack traces

**Persistent Issues:**
- Still biased toward code generation over debugging
- Symptom-focused fixes common
- Limited runtime understanding
- Can't actually "run" the debugger

**Best Practice:**
```
Treat the LLM as a debugging assistant, not a debugger.
You drive the investigation.
LLM suggests where to look and what to try.
You gather evidence.
Together identify root cause.
Then LLM helps implement the fix.
```

**Remember:** Good debugging is detective work. The LLM is your research assistant, but you're the detective. Don't let it jump to conclusions—make it show its work.
