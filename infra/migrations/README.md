# Database Migrations

**Purpose**  
This directory contains SQL migration files for evolving the database schema over time.

---

## Migration Files

Migrations are numbered sequentially and include both forward and rollback scripts.

### Current Migrations

- `001_add_unified_variant_config_support.sql` - Adds support for unified variant config structure while maintaining backward compatibility
- `002_add_prompt_registry.sql` - Creates exp.prompts and exp.prompt_versions tables for conversational AI prompt management

---

## Running Migrations

### Apply Migration

```bash
psql -d your_database -f infra/migrations/001_add_unified_variant_config_support.sql
```

### Verify Migration

After applying, verify the migration succeeded:

```sql
-- Check that the column comment was added
SELECT col_description('exp.variants'::regclass, 
    (SELECT ordinal_position FROM information_schema.columns 
     WHERE table_schema = 'exp' AND table_name = 'variants' AND column_name = 'config'));
```

### Rollback Migration

If needed, rollback using the instructions in the migration file comments.

---

## Migration Guidelines

1. **Always include rollback instructions** in migration file comments
2. **Test migrations** on a copy of production data before applying
3. **Update `infra/postgres-schema-overview.sql`** to reflect schema changes
4. **Maintain backward compatibility** when possible
5. **Document breaking changes** clearly in migration comments

---

## Testing Existing Configs

After applying migration `001_add_unified_variant_config_support.sql`, verify existing configs still work:

```sql
-- Test that existing configs are still valid JSONB
SELECT id, config 
FROM exp.variants 
WHERE config ? 'policy_version_id'
LIMIT 5;

-- Test that new unified config format can be inserted
INSERT INTO exp.variants (experiment_id, name, allocation, config)
VALUES (
    '00000000-0000-0000-0000-000000000001'::uuid,
    'test_variant',
    0.1,
    '{"execution_strategy": "mlflow_model", "mlflow_model": {"policy_version_id": "test-uuid"}, "params": {}}'::jsonb
);

-- Clean up test
DELETE FROM exp.variants WHERE name = 'test_variant';
```
