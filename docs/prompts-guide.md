# Prompt Management Guide

**Purpose**  
This guide explains how to create, version, and manage prompts for conversational AI projects using the prompt registry system.

---

## Start Here If…

- **Creating prompts for conversational AI projects** → Read this guide
- **Understanding prompt versioning** → Read this guide
- **Using prompts in experiments** → Read this guide
- **Already familiar with prompts** → Skip to [conversation-flows.md](conversation-flows.md) or [experiments.md](experiments.md)

---

## 1. Overview

The prompt registry system provides versioned prompt management for conversational AI projects (chatbots, LLM-powered assistants, structured dialogue systems), similar to how MLflow manages model versions for ML projects.

### 1.1 Key Concepts

| Concept | Description |
|---------|-------------|
| **Prompt** | A named prompt template (e.g., "meal_planning_assistant") |
| **Prompt Version** | A specific version of a prompt with associated LLM provider/model |
| **Prompt File** | Git-versioned text file in `/prompts/` directory |
| **Prompt Registry** | Database tables (`exp.prompts`, `exp.prompt_versions`) tracking metadata |

### 1.2 How It Works

1. **Create prompt file** in `/prompts/` directory (Git versioned)
2. **Register prompt** in database (`exp.prompts`, `exp.prompt_versions`)
3. **Use in experiments** via variant config with `prompt_version_id`
4. **Prompt Service** retrieves prompt content and metadata

**Related**: [architecture.md](architecture.md) (section on Prompt Service), [data-model.md](data-model.md) (section 4)

---

## 2. Creating Prompts

**Quick Reference:** See [Template Syntax Quick Reference](#quick-reference-template-syntax) below for Jinja2 syntax.

### 2.1 File Structure

Prompt files are stored in the `/prompts/` directory:

```
prompts/
├── meal_planning_v1.txt
├── meal_planning_v2.txt
└── customer_support_v1.txt
```

### 2.2 File Naming Convention

Prompt files follow this pattern:

```
{prompt_name}_v{version}.txt
```

**Examples:**
- `meal_planning_v1.txt` - Meal planning assistant, version 1
- `meal_planning_v2.txt` - Meal planning assistant, version 2
- `customer_support_v1.txt` - Customer support bot, version 1

**Rules:**
- Use lowercase letters and underscores for prompt names
- Version numbers start at 1 and increment sequentially
- File extension is always `.txt`
- No spaces in filenames

### 2.3 Basic Prompt Example

Create a simple prompt file:

```text
You are a helpful meal planning assistant. Your goal is to help users plan meals based on their preferences, dietary restrictions, and available ingredients.

When helping users:
- Ask about their dietary preferences (vegetarian, vegan, allergies, etc.)
- Consider their favorite cuisines
- Suggest balanced meals with variety
- Provide practical meal planning tips

Be friendly, concise, and helpful.
```

### 2.4 Template Syntax (Jinja2)

Prompts support template variables using **Jinja2** syntax. **Full syntax:** [Jinja2 documentation](https://jinja.palletsprojects.com/). **Examples:** [examples/conversational-assistant/](../examples/conversational-assistant/)

#### Variables

Use `{{ variable_name }}` for variable substitution:

```text
Hello {{ user_name }}!

Today is {{ current_date }}. Here are your meal suggestions for today.
```

#### Conditionals

Use `{% if condition %}...{% endif %}` for conditional content:

```text
{% if user_preference == "vegetarian" %}
You prefer vegetarian meals. I'll make sure all suggestions are vegetarian-friendly.
{% else %}
You have no dietary restrictions. I'll suggest a variety of meals.
{% endif %}
```

#### Loops

Use `{% for item in items %}...{% endfor %}` for loops:

```text
Your favorite cuisines are:
{% for cuisine in favorite_cuisines %}
- {{ cuisine }}
{% endfor %}
```

#### Complete Template Example

```text
You are a helpful meal planning assistant for {{ user_name }}.

{% if dietary_restrictions %}
Dietary restrictions: {{ dietary_restrictions }}
{% endif %}

{% if favorite_cuisines %}
Favorite cuisines:
{% for cuisine in favorite_cuisines %}
- {{ cuisine }}
{% endfor %}
{% endif %}

Based on this information, suggest a meal plan for the week.
```

**Related**: [prompts/README.md](../prompts/README.md) for more template examples

---

## 3. Versioning Prompts

### 3.1 Version Numbering

- **Version 1:** Initial version of a prompt
- **Version 2, 3, etc.:** Subsequent iterations with improvements
- Versions are sequential integers (1, 2, 3, ...)
- Each version is stored as a separate file

### 3.2 Creating New Versions

When updating a prompt:

1. **Copy the previous version:**
   ```bash
   cp prompts/meal_planning_v1.txt prompts/meal_planning_v2.txt
   ```

2. **Edit the new file** with your changes

3. **Update database records** in `exp.prompt_versions` table (see section 4)

4. **Commit to Git** for version control:
   ```bash
   git add prompts/meal_planning_v2.txt
   git commit -m "Add meal_planning_v2: Improved dietary restriction handling"
   ```

### 3.3 Version History

Git provides version history for prompt files:

- **View changes:** `git log prompts/meal_planning_v1.txt`
- **Compare versions:** `git diff prompts/meal_planning_v1.txt prompts/meal_planning_v2.txt`
- **Revert changes:** `git checkout HEAD~1 -- prompts/meal_planning_v1.txt`

---

## 4. Registering Prompts

### 4.1 Database Schema

Prompts are registered in two database tables:

**exp.prompts** - Named prompts:
```sql
CREATE TABLE exp.prompts (
    id              UUID PRIMARY KEY,
    name            VARCHAR(255) UNIQUE NOT NULL,
    description     TEXT,
    created_at      TIMESTAMP
);
```

**exp.prompt_versions** - Versioned prompt configurations:
```sql
CREATE TABLE exp.prompt_versions (
    id                  UUID PRIMARY KEY,
    prompt_id           UUID REFERENCES exp.prompts(id),
    version             INTEGER NOT NULL,
    file_path           VARCHAR(500) NOT NULL,  -- e.g., "prompts/meal_planning_v1.txt"
    model_provider      VARCHAR(100) NOT NULL,  -- e.g., "anthropic", "openai"
    model_name          VARCHAR(255) NOT NULL,  -- e.g., "claude-sonnet-4.5"
    config_defaults     JSONB,                  -- Default params (temperature, etc.)
    status              VARCHAR(50),             -- active | deprecated | archived
    created_at          TIMESTAMP,
    UNIQUE(prompt_id, version)
);
```

**Related**: [data-model.md](data-model.md) (section 4) for complete schema

### 4.2 Registration Process

#### Step 1: Create Prompt Record

```sql
INSERT INTO exp.prompts (name, description)
VALUES ('meal_planning_assistant', 'Assistant for helping users plan meals');
```

#### Step 2: Create Prompt Version Record

```sql
INSERT INTO exp.prompt_versions (
    prompt_id, 
    version, 
    file_path,
    model_provider,
    model_name,
    config_defaults,
    status
)
VALUES (
    (SELECT id FROM exp.prompts WHERE name = 'meal_planning_assistant'),
    1,
    'prompts/meal_planning_v1.txt',
    'anthropic',
    'claude-sonnet-4.5',
    '{"temperature": 0.7, "max_tokens": 2048}'::jsonb,
    'active'
);
```

#### Step 3: Verify File Path

- Path is **relative to repository root**
- Example: `prompts/meal_planning_v1.txt` (not `/prompts/meal_planning_v1.txt`)
- File must exist in `/prompts/` directory

### 4.3 Using Configuration Files

Alternatively, use the YAML configuration format:

```yaml
prompts:
  - name: meal_planning_assistant
    description: "Assistant for helping users plan meals"
    
    versions:
      - version: 1
        description: "Initial version with basic planning"
        file: prompts/meal_planning_v1.txt
        model_provider: anthropic
        model_name: claude-sonnet-4.5
        status: active
        params:
          temperature: 0.7
          max_tokens: 2048
```

**Related**: [../config/prompts.example.yml](../config/prompts.example.yml) for complete examples

---

## 5. Using Prompts in Experiments

### 5.1 Variant Configuration

Reference prompts in experiment variant configs using `prompt_version_id`:

```yaml
experiments:
  - name: chatbot_assistant_exp
    variants:
      - name: control
        allocation: 0.5
        config:
          execution_strategy: "prompt_template"
          prompt_config:
            prompt_version_id: "770e8400-e29b-41d4-a716-446655440002"  # UUID from DB
            model_provider: "anthropic"
            model_name: "claude-sonnet-4.5"
          params:
            temperature: 0.7
            max_tokens: 2048
```

### 5.2 Retrieving Prompt Content

The Prompt Service retrieves prompt content:

1. Query `exp.prompt_versions` for metadata (including `file_path`)
2. Read file content from `/prompts/` directory using `file_path`
3. Combine metadata + content for API response

**API Example:**

```bash
curl -X GET "https://api.example.com/api/v1/prompt-versions/770e8400-e29b-41d4-a716-446655440002" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response:**

```json
{
  "id": "770e8400-e29b-41d4-a716-446655440002",
  "prompt_id": "550e8400-e29b-41d4-a716-446655440000",
  "prompt_name": "meal_planning_assistant",
  "version": 1,
  "file_path": "prompts/meal_planning_v1.txt",
  "content": "You are a helpful meal planning assistant...",
  "model_provider": "anthropic",
  "model_name": "claude-sonnet-4.5",
  "config_defaults": {
    "temperature": 0.7,
    "max_tokens": 2048
  },
  "status": "active"
}
```

**Related**: [../services/prompt-service/API_SPEC.md](../services/prompt-service/API_SPEC.md) for API details

---

## 6. Status Management

### 6.1 Status Values

| Status | Description | Usage |
|--------|-------------|-------|
| `active` | Currently in use | Can be assigned to variants in experiments |
| `deprecated` | No longer recommended | Still works but should migrate to newer version |
| `archived` | Retired | Not available for new assignments |

### 6.2 Status Lifecycle

```
┌─────────┐     ┌──────────────┐     ┌──────────┐
│ Active  │ ──► │ Deprecated   │ ──► │ Archived │
└─────────┘     └──────────────┘     └──────────┘
     │
     │ (can stay active)
     │
     └─────────────────────────────────┘
```

**Best Practices:**
- Mark old versions as `deprecated` when new versions are available
- Archive versions that are no longer needed
- Keep at least one `active` version per prompt

---

## 7. Best Practices

### 7.1 Prompt Design

- **Keep prompts focused:** Each prompt should have a single, clear purpose
- **Avoid overly long prompts:** Keep under 2000 words when possible
- **Break complex prompts:** Split into multiple versions or multiple prompts
- **Use clear instructions:** Be explicit about desired behavior
- **Include examples:** Show expected input/output format when helpful

### 7.2 Version Control

- **Document changes:** Use Git commit messages to explain why changes were made
- **Meaningful commits:** Include version notes in commit messages:
  ```
  Update meal_planning_v2.txt: Add dietary restriction handling
  
  - Added support for vegetarian/vegan preferences
  - Improved allergy handling
  - Better portion size recommendations
  ```
- **Test before deploying:** Test prompt templates with sample variables
- **Verify syntax:** Check that Jinja2 template syntax is valid

### 7.3 File Organization

- **One file per version:** Each version should have its own file
- **Keep related prompts together:** Use consistent naming (same prefix)
- **Use descriptive names:** Make prompt purpose clear from filename
- **Follow naming convention:** Use `{name}_v{version}.txt` format

### 7.4 Model Selection

- **Choose appropriate model:** Match model capabilities to prompt complexity
- **Consider cost:** Balance model cost with performance needs
- **Test different models:** Experiment with different providers/models
- **Document model choice:** Explain why specific model was chosen

---

## 8. Common Patterns

### 8.1 A/B Testing Prompts

Test different prompt versions in the same experiment:

```yaml
experiments:
  - name: prompt_ab_test
    description: "Compare two prompt versions for meal planning assistant"
    unit_type: user
    status: active
    variants:
      - name: control
        description: "Original prompt version"
        allocation: 0.5
        config:
          execution_strategy: "prompt_template"
          prompt_config:
            prompt_version_id: "550e8400-e29b-41d4-a716-446655440000"  # Replace with actual UUID
            model_provider: "anthropic"
            model_name: "claude-sonnet-4.5"
          params:
            temperature: 0.7
            max_tokens: 2048
      - name: improved
        description: "Improved prompt with better instructions"
        allocation: 0.5
        config:
          execution_strategy: "prompt_template"
          prompt_config:
            prompt_version_id: "660e8400-e29b-41d4-a716-446655440001"  # Replace with actual UUID
            model_provider: "anthropic"
            model_name: "claude-sonnet-4.5"
          params:
            temperature: 0.7
            max_tokens: 2048
```

**Note:** Always replace placeholder UUIDs with actual `prompt_version_id` values from your database. Verify UUIDs exist before creating experiments.

### 8.2 Gradual Rollout

Gradually increase allocation for new prompt version:

```yaml
# Week 1: 10% allocation (safe start)
experiments:
  - name: prompt_rollout_week1
    description: "Initial rollout of improved prompt"
    unit_type: user
    status: active
    variants:
      - name: control
        allocation: 0.9
        config:
          execution_strategy: "prompt_template"
          prompt_config:
            prompt_version_id: "550e8400-e29b-41d4-a716-446655440000"
            model_provider: "anthropic"
            model_name: "claude-sonnet-4.5"
      - name: new_version
        allocation: 0.1  # Start small!
        config:
          execution_strategy: "prompt_template"
          prompt_config:
            prompt_version_id: "660e8400-e29b-41d4-a716-446655440001"
            model_provider: "anthropic"
            model_name: "claude-sonnet-4.5"

# Week 2: 50% allocation (if metrics look good)
# Update the same experiment or create new one with updated allocations
variants:
  - name: control
    allocation: 0.5
  - name: new_version
    allocation: 0.5
```

**Best Practice:** Monitor metrics (completion rate, satisfaction, etc.) before increasing allocation. Only proceed if new version performs as well or better than control.

### 8.3 Multi-Model Testing

Test same prompt with different models:

```yaml
variants:
  - name: claude_model
    config:
      prompt_config:
        prompt_version_id: "uuid-prompt-v1"
        model_provider: "anthropic"
        model_name: "claude-sonnet-4.5"
  - name: gpt_model
    config:
      prompt_config:
        prompt_version_id: "uuid-prompt-v1"  # Same prompt
        model_provider: "openai"
        model_name: "gpt-4"
```

---

## 9. Common Mistakes

### 9.1 Prompt Versioning Mistakes

**Mistake: Modifying prompt file without creating new version**

- **Problem:** Directly editing an active prompt file breaks reproducibility
- **Solution:** Always create a new version file (e.g., `v2.txt`) when making changes
- **Why:** Active prompts may be in use in production experiments

**Mistake: Inconsistent version numbering**

- **Problem:** Skipping version numbers or using non-sequential numbers causes confusion
- **Solution:** Always increment versions sequentially (1, 2, 3, ...)
- **Why:** Makes it easier to track prompt evolution and rollback if needed

**Mistake: Not updating database when creating new prompt file**

- **Problem:** Prompt file exists but isn't registered in database, so it can't be used
- **Solution:** Always create corresponding `exp.prompt_versions` record after creating file
- **Why:** Prompt Service queries database, not file system directly

### 9.2 Template Syntax Mistakes

**Mistake: Incorrect Jinja2 variable syntax**

- **Problem:** Using `{variable}` instead of `{{variable}}` or mixing syntaxes
- **Solution:** Always use double curly braces: `{{ variable_name }}`
- **Example:** 
  - ❌ Wrong: `Hello {user_name}`
  - ✅ Correct: `Hello {{ user_name }}`

**Mistake: Not handling missing variables**

- **Problem:** Template fails when variable is undefined
- **Solution:** Use default filters: `{{ user_name | default('Guest') }}`
- **Why:** Prevents template rendering errors

**Mistake: Complex logic in templates**

- **Problem:** Putting too much business logic in prompt templates makes them hard to maintain
- **Solution:** Keep templates simple, do complex logic in application code
- **Why:** Templates should focus on prompt structure, not computation

### 9.3 Configuration Mistakes

**Mistake: Using wrong prompt_version_id in experiment config**

- **Problem:** Experiment references non-existent or wrong prompt version
- **Solution:** Always verify UUID exists in `exp.prompt_versions` before using in config
- **Check:** Query database: `SELECT id, version FROM exp.prompt_versions WHERE prompt_id = '...'`

**Mistake: Mismatched model_provider and model_name**

- **Problem:** Using OpenAI model name with Anthropic provider (or vice versa)
- **Solution:** Verify model_provider matches the model_name's actual provider
- **Example:** 
  - ❌ Wrong: `model_provider: "anthropic"`, `model_name: "gpt-4"`
  - ✅ Correct: `model_provider: "openai"`, `model_name: "gpt-4"`

**Mistake: Not setting appropriate status**

- **Problem:** Leaving deprecated prompts as 'active' causes confusion
- **Solution:** Update status to 'deprecated' when new version is available
- **Why:** Prevents accidental use of outdated prompts

---

## 10. Troubleshooting

### 10.1 Common Issues

**Issue: Prompt file not found**

- **Symptom:** Prompt Service returns 404 or file not found error
- **Solution:** Verify `file_path` in database matches actual file location
- **Check:** File path is relative to repository root (e.g., `prompts/meal_planning_v1.txt`)
- **Debug steps:**
  1. Check file exists: `ls prompts/meal_planning_v1.txt`
  2. Verify path in database: `SELECT file_path FROM exp.prompt_versions WHERE id = '...'`
  3. Ensure no leading slash: path should be `prompts/file.txt`, not `/prompts/file.txt`

**Issue: Template variables not substituted**

- **Symptom:** Variables appear as `{{ variable_name }}` in output
- **Solution:** Ensure template rendering is configured correctly
- **Check:** Verify Jinja2 syntax is correct
- **Debug steps:**
  1. Check for typos in variable names
  2. Verify variable is passed to template renderer
  3. Test template with sample data: `render_template(prompt_content, {'variable': 'test'})`

**Issue: Wrong prompt version retrieved**

- **Symptom:** Different prompt content than expected
- **Solution:** Verify `prompt_version_id` in variant config matches database
- **Check:** Query `exp.prompt_versions` to confirm version details
- **Debug steps:**
  1. Get prompt version from API: `GET /api/v1/prompt-versions/{id}`
  2. Compare returned `version` number with expected version
  3. Check if multiple versions exist and wrong one is active

**Issue: Prompt content outdated**

- **Symptom:** Prompt file updated but API still returns old content
- **Solution:** Prompt Service caches file content; restart service or clear cache
- **Check:** Verify file modification time matches expected update time
- **Debug steps:**
  1. Check file modification: `ls -l prompts/meal_planning_v1.txt`
  2. Verify Git shows changes: `git log prompts/meal_planning_v1.txt`
  3. Restart Prompt Service to reload cache

**Issue: Database and file mismatch**

- **Symptom:** Database record exists but file doesn't, or vice versa
- **Solution:** Ensure both database record and file exist and match
- **Check:** Compare `file_path` in database with actual file system
- **Debug steps:**
  1. List all prompt files: `ls prompts/`
  2. Query database: `SELECT file_path FROM exp.prompt_versions`
  3. Ensure every database record has corresponding file

### 10.2 Debugging Tips

- **Check file exists:** `ls prompts/meal_planning_v1.txt`
- **Verify database record:** Query `exp.prompt_versions` for prompt version
- **Test API:** Call Prompt Service API directly to see returned content
- **Check Git history:** `git log prompts/meal_planning_v1.txt` to see changes
- **Validate template syntax:** Use Jinja2 parser to check for syntax errors
- **Compare versions:** Use `git diff prompts/meal_planning_v1.txt prompts/meal_planning_v2.txt`
- **Check service logs:** Review Prompt Service logs for errors or warnings

---

## 11. Further Exploration

- **Understanding conversation flows** → [conversation-flows.md](conversation-flows.md)
- **Using prompts in experiments** → [experiments.md](experiments.md) (section 4.4)
- **Prompt Service API** → [../services/prompt-service/API_SPEC.md](../services/prompt-service/API_SPEC.md)
- **Prompt Service design** → [../services/prompt-service/DESIGN.md](../services/prompt-service/DESIGN.md)
- **Data model details** → [data-model.md](data-model.md) (section 4)
- **Example prompts** → [../prompts/README.md](../prompts/README.md)
- **Configuration examples** → [../config/prompts.example.yml](../config/prompts.example.yml)
- **Complete example project** → [../examples/conversational-assistant/README.md](../examples/conversational-assistant/README.md)
- **Conversational AI quickstart** → [routes/conversational-ai-route.md](routes/conversational-ai-route.md)

**See Also:**
- [choosing-project-type.md](choosing-project-type.md) - Help deciding if prompts are right for your project
- [mcp-integration.md](mcp-integration.md) - Using MCP tools with prompts
- [experiments.md](experiments.md) - Configuring experiments with prompts

---

## Quick Reference: Template Syntax

### Jinja2 Variables
- **Basic:** `{{ variable_name }}`
- **With default:** `{{ variable_name | default('default_value') }}`
- **With filter:** `{{ list | join(', ') }}`

### Conditionals
```jinja2
{% if condition %}
  content
{% else %}
  alternative
{% endif %}
```

### Loops
```jinja2
{% for item in items %}
  - {{ item }}
{% endfor %}
```

### Common Filters
- `default('value')` - Default if undefined
- `join(', ')` - Join array with separator
- `upper` - Convert to uppercase
- `lower` - Convert to lowercase

---

## After Completing This Document

You will understand:
- How to create and version prompts
- Template syntax (Jinja2) for dynamic content
- How to register prompts in the database
- How to use prompts in experiments
- Best practices for prompt management
- Common mistakes and how to avoid them

**Next Step**: [conversation-flows.md](conversation-flows.md) or [experiments.md](experiments.md)
