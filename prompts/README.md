# Prompts Directory

This directory contains versioned prompt template files for conversational AI projects. Prompts are stored as plain text files and managed through Git version control.

---

## Directory Structure

```
prompts/
├── README.md                    # This file
├── meal_planning_v1.txt         # Example: Meal planning assistant v1
├── meal_planning_v2.txt         # Example: Meal planning assistant v2
└── customer_support_v1.txt      # Example: Customer support bot v1
```

---

## File Naming Convention

Prompt files follow this naming pattern:

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

---

## Versioning

### Version Numbering

- **Version 1:** Initial version of a prompt
- **Version 2, 3, etc.:** Subsequent iterations with improvements
- Versions are sequential integers (1, 2, 3, ...)
- Each version is stored as a separate file

### Creating New Versions

When updating a prompt:

1. **Copy the previous version:**
   ```bash
   cp prompts/meal_planning_v1.txt prompts/meal_planning_v2.txt
   ```

2. **Edit the new file** with your changes

3. **Update database records** in `exp.prompt_versions` table (separate process)

4. **Commit to Git** for version control

### Version History

Git provides version history for prompt files:
- View changes: `git log prompts/meal_planning_v1.txt`
- Compare versions: `git diff prompts/meal_planning_v1.txt prompts/meal_planning_v2.txt`
- Revert changes: `git checkout HEAD~1 -- prompts/meal_planning_v1.txt`

---

## Template Syntax

Prompts support template variables using **Jinja2** syntax for variable substitution.

### Variables

Use `{{ variable_name }}` for variable substitution:

```
You are a helpful assistant for {{ user_name }}.

Today is {{ current_date }}.
```

### Conditionals

Use `{% if condition %}...{% endif %}` for conditional content:

```
{% if user_preference == "vegetarian" %}
You prefer vegetarian meals.
{% else %}
You have no dietary restrictions.
{% endif %}
```

### Loops

Use `{% for item in items %}...{% endfor %}` for loops:

```
Your favorite cuisines are:
{% for cuisine in favorite_cuisines %}
- {{ cuisine }}
{% endfor %}
```

### Example with Template Syntax

See `meal_planning_v1.txt` for a complete example with template variables.

---

## Linking to Database Records

Prompt files are linked to database records in the `exp.prompt_versions` table:

### Database Schema

```sql
-- exp.prompts: Named prompts
CREATE TABLE exp.prompts (
    id UUID PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP
);

-- exp.prompt_versions: Versioned prompt configurations
CREATE TABLE exp.prompt_versions (
    id UUID PRIMARY KEY,
    prompt_id UUID REFERENCES exp.prompts(id),
    version INTEGER NOT NULL,
    file_path VARCHAR(500) NOT NULL,  -- Links to file in /prompts/
    model_provider VARCHAR(100) NOT NULL,
    model_name VARCHAR(255) NOT NULL,
    config_defaults JSONB,
    status VARCHAR(50),
    created_at TIMESTAMP,
    UNIQUE(prompt_id, version)
);
```

### Linking Process

1. **Create prompt record** in `exp.prompts`:
   ```sql
   INSERT INTO exp.prompts (name, description)
   VALUES ('meal_planning_assistant', 'Assistant for meal planning');
   ```

2. **Create prompt version record** in `exp.prompt_versions`:
   ```sql
   INSERT INTO exp.prompt_versions (
       prompt_id, 
       version, 
       file_path,  -- e.g., "prompts/meal_planning_v1.txt"
       model_provider,
       model_name,
       status
   )
   VALUES (
       (SELECT id FROM exp.prompts WHERE name = 'meal_planning_assistant'),
       1,
       'prompts/meal_planning_v1.txt',
       'anthropic',
       'claude-sonnet-4.5',
       'active'
   );
   ```

3. **File path format:**
   - Path is **relative to repository root**
   - Example: `prompts/meal_planning_v1.txt` (not `/prompts/meal_planning_v1.txt`)
   - Must match actual file location

### Retrieving Prompts

The Prompt Service reads prompt content from files:

1. Query `exp.prompt_versions` for metadata (including `file_path`)
2. Read file content from `/prompts/` directory using `file_path`
3. Combine metadata + content for API response

See `services/prompt-service/DESIGN.md` for implementation details.

---

## Best Practices

### 1. Keep Prompts Focused

- Each prompt should have a single, clear purpose
- Avoid overly long prompts (>2000 words)
- Break complex prompts into multiple versions

### 2. Document Changes

- Use Git commit messages to document why changes were made
- Include version notes in commit messages:
  ```
  Update meal_planning_v2.txt: Add dietary restriction handling
  
  - Added support for vegetarian/vegan preferences
  - Improved allergy handling
  - Better portion size recommendations
  ```

### 3. Test Before Deploying

- Test prompt templates with sample variables
- Verify template syntax is valid
- Check that variables are properly substituted

### 4. Version Control

- Always commit prompt changes to Git
- Use meaningful commit messages
- Tag major versions if needed

### 5. File Organization

- One prompt file per version
- Keep related prompts together (same prefix)
- Use descriptive names

---

## Example Files

This directory includes example prompts:

- **meal_planning_v1.txt** - Meal planning assistant with template variables
- **customer_support_v1.txt** - Customer support bot example

These examples demonstrate:
- Template variable usage
- Conditional logic
- Best practices for prompt structure

---

## Related Documentation

- [Prompt Service Design](../../services/prompt-service/DESIGN.md) - How prompts are served
- [Prompt Service API](../../services/prompt-service/API_SPEC.md) - API for retrieving prompts
- [Data Model](../../docs/data-model.md) - Database schema (section 4)
- [Prompts Guide](../../docs/prompts-guide.md) - User guide (coming in Phase 2)

---

## Questions?

For questions about prompt management, see the [Prompts Guide](../../docs/prompts-guide.md) or contact the platform team.
