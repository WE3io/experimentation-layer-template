# AI-Assisted Learning Prompts

**Purpose**  
This document provides prompts for engaging with AI coding assistants while learning this system. These prompts are designed to keep you in the driver's seat — learning actively rather than passively consuming AI-generated answers.

---

## How to Use This Guide

1. **Before asking AI for help**, find the relevant prompt category below
2. **Use the prompt templates** to structure your interaction
3. **Do the thinking first**, then use AI to verify or extend
4. **Reflect** on what you learned after each interaction

---

## Philosophy: The 70/20/10 Rule

When learning with AI assistance:
- **70%** — You do the thinking, writing, and designing first
- **20%** — AI reviews, critiques, and fills gaps
- **10%** — AI generates examples or boilerplate only after you understand

If you find yourself copy-pasting AI output without understanding it, pause and use a "Comprehension Check" prompt below.

---

## 1. Comprehension Check Prompts

Use these to verify you actually understand what you've read.

### After reading a section:
```
I just read about [TOPIC]. I'm going to explain it in my own words. 
Point out anything I get wrong or miss:

[YOUR EXPLANATION HERE]
```

### Before moving to the next document:
```
I need to explain [CONCEPT] to a colleague who hasn't read this doc.
Quiz me with 3-4 questions to test whether I actually understand it,
not just recognize the words. Don't give me the answers until I attempt them.
```

### Testing your mental model:
```
I think [CONCEPT] works like this: [YOUR UNDERSTANDING].
Is this mental model correct? What edge cases would break it?
```

---

## 2. Prediction Prompts

Use these BEFORE reading a new section to engage your prior knowledge.

### Before reading a new topic:
```
I'm about to read about [TOPIC] in this experimentation system.
Before I do, I want to predict how it might work based on what I know so far.
Don't tell me the answer yet — just ask me clarifying questions about my prediction:

My prediction: [YOUR GUESS]
```

### After making a prediction:
```
I predicted [X] but the actual approach is [Y]. 
Help me understand why my intuition was wrong.
What assumptions did I make that don't hold?
```

---

## 3. Design-First Prompts

Use these when you need to create something. Design first, then compare.

### Before writing configuration:
```
I need to create [CONFIG TYPE] for [SCENARIO].
Don't write it for me. Instead, ask me questions about my requirements
and constraints. After I've thought through them, I'll write it myself.
```

### After writing your own design:
```
I designed this [SCHEMA/CONFIG/STRUCTURE] for [PURPOSE]:

[YOUR DESIGN]

Review it critically. What did I miss? What would break in production?
Don't rewrite it — just point out the issues so I can fix them myself.
```

### Comparing your approach:
```
Here's my approach to [PROBLEM]: [YOUR SOLUTION]
Here's the reference approach from the docs: [REFERENCE]

What are the trade-offs between these? When would mine be better?
When would the reference be better?
```

---

## 4. Debug and Diagnose Prompts

Use these to build troubleshooting intuition.

### Learning to diagnose:
```
Something is broken: [SYMPTOM].
Don't give me the solution. Instead, walk me through how to diagnose this.
What would you check first? What questions would you ask?
I'll tell you what I find at each step.
```

### Building debugging intuition:
```
What are the 5 most common mistakes developers make when working with 
[COMPONENT: e.g., experiment configuration / event logging / training pipeline]?
For each one, what symptom would I see, and how would I confirm that's the cause?
```

### After fixing a bug:
```
I just fixed a bug where [SYMPTOM] was caused by [ROOT CAUSE].
Help me generalize this: what category of bug is this?
What could I have done to prevent it? What should I watch for next time?
```

---

## 5. Decision-Making Prompts

Use these when facing ambiguous choices.

### Working through trade-offs:
```
I need to decide between [OPTION A] and [OPTION B] for [SITUATION].
Don't tell me which to choose. Instead, help me think through it:
- What are the trade-offs of each?
- What questions should I ask to make this decision?
- What would change my answer?
```

### Scenario analysis:
```
I'm considering [DECISION: e.g., promoting this model / setting allocation to X%].
Play devil's advocate. What could go wrong? What am I not considering?
```

### Explaining your reasoning:
```
I decided to [DECISION] because [REASONING].
Poke holes in my reasoning. What assumptions am I making?
What evidence would prove me wrong?
```

---

## 6. Teaching-Back Prompts

Use these to solidify understanding by teaching.

### Explain to verify:
```
I'm going to explain [CONCEPT] to you as if you're a new team member.
Interrupt me if I'm wrong, unclear, or missing something important:

[YOUR EXPLANATION]
```

### Create an analogy:
```
Help me create an analogy for [CONCEPT] that I could use to explain it
to someone without ML/engineering background. 
I'll propose one first: [YOUR ANALOGY]
Is this accurate? What does it miss?
```

### Document what you learned:
```
I need to write a one-paragraph summary of [TOPIC] for my own notes.
Here's my draft:

[YOUR SUMMARY]

Is this accurate and complete? What's the one thing I should add?
```

---

## 7. Implementation Planning Prompts

Use these when you're ready to build.

### Before implementing:
```
I'm about to implement [COMPONENT].
Before I start, quiz me on the requirements. Make sure I understand:
- What inputs/outputs are expected
- What invariants must hold
- What error cases to handle
Don't write any code — just verify I understand the problem.
```

### Structuring your approach:
```
I need to implement [FEATURE]. Here's my plan:
1. [STEP 1]
2. [STEP 2]
3. [STEP 3]

Review my plan. What am I missing? What order would you change?
What's the riskiest part I should prototype first?
```

### Code review before writing:
```
I'm about to write [CODE TYPE]. Before I do, what are the 3 things
I'm most likely to get wrong based on common mistakes in this area?
```

---

## 8. Connection-Making Prompts

Use these to link new knowledge to what you already know.

### Relating to experience:
```
How does [CONCEPT FROM DOCS] relate to [SIMILAR CONCEPT I KNOW]?
What's the same? What's different? When would I use one vs the other?
```

### Seeing the big picture:
```
I've now read about [COMPONENT A] and [COMPONENT B].
Help me understand how they interact. If I change X in A, what happens in B?
Walk me through a concrete example.
```

### Finding patterns:
```
I notice that [PATTERN I OBSERVED] appears in multiple places.
Is this intentional? What principle does it reflect?
```

---

## 9. Rubber Duck Prompts

Use these when you're stuck.

### Unsticking yourself:
```
I'm stuck on [PROBLEM]. Don't solve it for me.
Ask me questions to help me think through it:
- What have I tried?
- What do I think is happening?
- What would I check next?
```

### Clarifying confusion:
```
I'm confused about [TOPIC]. I think my confusion is because [HYPOTHESIS].
Help me figure out what I'm actually confused about by asking me questions.
```

---

## 10. Progress Check Prompts

Use these at transition points in your learning.

### Before starting a new route:
```
I'm about to start the [ROUTE NAME] learning path.
Based on what I should already know, quiz me to see if I'm ready.
If I have gaps, tell me what to review first.
```

### After completing a section:
```
I just finished reading [SECTION/DOCUMENT].
Ask me 3 questions that a senior engineer would ask to verify I understood it.
Start with the questions only — I'll answer before you give feedback.
```

### Weekly reflection:
```
This week I learned about [TOPICS].
Help me consolidate: what are the 3 most important things I should remember?
What's one thing I should revisit because I'm probably still shaky on it?
```

---

## Anti-Patterns to Avoid

❌ **Don't**: "Explain [concept] to me"  
✅ **Do**: "I think [concept] means [your understanding]. Am I right?"

❌ **Don't**: "Write me a config for [scenario]"  
✅ **Do**: "Review my config for [scenario] and point out issues"

❌ **Don't**: "What's the answer to [question]?"  
✅ **Do**: "I think the answer is [X] because [reasoning]. Check my logic."

❌ **Don't**: "Debug this for me"  
✅ **Do**: "Help me build a debugging checklist for this type of issue"

---

## Quick Reference Card

| Learning Stage | Prompt Type |
|----------------|-------------|
| Before reading | Prediction prompts |
| After reading | Comprehension check prompts |
| Creating something | Design-first prompts |
| Making decisions | Decision-making prompts |
| Stuck | Rubber duck prompts |
| Reviewing progress | Progress check prompts |
| Building intuition | Debug and diagnose prompts |

---

## Final Note

The goal isn't to avoid using AI — it's to use AI in a way that builds your understanding rather than replacing it. 

If you find yourself unable to explain something without looking it up, that's a signal to go back and use the comprehension check prompts.

**The test**: After completing this material, could you design a similar system from scratch? If not, you were a passenger. Go back and engage more actively.

---

## Related Documentation

- [README.md](README.md) — Main entry point
- [docs/README.md](README.md) — Documentation index
- [onboarding-spec.md](../onboarding-spec.md) — Full specification

