# Prompt Service Design

**Purpose**  
This document describes the internal design and architecture decisions for the Prompt Service, which manages versioned prompt templates for conversational AI projects.

---

## Start Here If…

- **Implementing the service** → Read this document
- **Calling the service** → Go to [API_SPEC.md](API_SPEC.md)
- **Understanding prompts** → Go to [../../docs/prompts-guide.md](../../docs/prompts-guide.md) (coming in Phase 2)
- **Understanding data model** → Go to [../../docs/data-model.md](../../docs/data-model.md) section 4

---

## 1. Service Overview

### 1.1 Responsibilities

| Responsibility | Description |
|----------------|-------------|
| Prompt Retrieval | Retrieve prompt versions by ID with full content |
| Version Management | List prompts and their versions |
| File System Integration | Read prompt content from `/prompts/` directory |
| Caching | Reduce file system and database load |
| Content Loading | Load prompt template content from Git-versioned files |

### 1.2 Non-Responsibilities

| Not Responsible For | Handled By |
|---------------------|------------|
| Prompt creation/updates | Admin tooling or separate service |
| Template rendering | Client application or separate rendering service |
| LLM API calls | Client application or LLM gateway |
| Experiment assignment | Assignment Service |

---

## 2. Architecture

### 2.1 Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                  Prompt Service                               │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   API Layer  │ ──►│   Business   │ ──►│   Data       │  │
│  │              │    │   Logic      │    │   Access     │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         │                    │                    │         │
│         │                    ▼                    ▼         │
│         │             ┌──────────────┐    ┌──────────────┐ │
│         │             │   Cache      │    │   Database   │ │
│         │             │   (Redis)    │    │   (Postgres) │ │
│         │             └──────────────┘    └──────────────┘ │
│         │                                              │     │
│         └──────────────────┬──────────────────────────┘     │
│                            ▼                                 │
│                    ┌──────────────┐                         │
│                    │   File       │                         │
│                    │   System     │                         │
│                    │   (/prompts/)│                         │
│                    └──────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

```
1. Request arrives at API layer (GET /prompt-versions/{id})
2. API validates request (UUID format)
3. Business logic checks cache for prompt version
4. If cache miss:
   a. Query database for prompt version metadata
   b. Read prompt content from file system (/prompts/ directory)
   c. Combine metadata + content
   d. Update cache
5. Return prompt version with content
```

---

## 3. Prompt Retrieval

### 3.1 Get Prompt Version by ID

**Database Query:**

```sql
SELECT 
    pv.id,
    pv.prompt_id,
    p.name as prompt_name,
    pv.version,
    pv.file_path,
    pv.model_provider,
    pv.model_name,
    pv.config_defaults,
    pv.status,
    pv.created_at
FROM exp.prompt_versions pv
JOIN exp.prompts p ON pv.prompt_id = p.id
WHERE pv.id = $1;
```

**File System Access:**

```pseudo
function load_prompt_content(file_path):
    """
    Load prompt content from file system.
    File path is relative to repository root.
    """
    # Resolve absolute path
    repo_root = get_repo_root()
    absolute_path = join_path(repo_root, file_path)
    
    # Validate path is within repo root (security)
    if not is_within_directory(repo_root, absolute_path):
        raise SecurityError("Invalid file path")
    
    # Read file content
    try:
        content = read_file(absolute_path)
        return content
    except FileNotFoundError:
        raise PromptFileNotFoundError(file_path)
    except IOError:
        raise PromptFileReadError(file_path)
```

**Response Assembly:**

```pseudo
function get_prompt_version(prompt_version_id):
    """
    Retrieve prompt version with content.
    """
    # Check cache first
    cache_key = f"prompt_version:{prompt_version_id}"
    cached = redis.get(cache_key)
    if cached:
        return json.parse(cached)
    
    # Query database
    version_metadata = db.query(
        "SELECT ... FROM exp.prompt_versions WHERE id = $1",
        prompt_version_id
    )
    
    if not version_metadata:
        raise PromptVersionNotFoundError(prompt_version_id)
    
    # Load content from file system
    content = load_prompt_content(version_metadata.file_path)
    
    # Assemble response
    response = {
        "id": version_metadata.id,
        "prompt_id": version_metadata.prompt_id,
        "prompt_name": version_metadata.prompt_name,
        "version": version_metadata.version,
        "file_path": version_metadata.file_path,
        "content": content,
        "model_provider": version_metadata.model_provider,
        "model_name": version_metadata.model_name,
        "config_defaults": version_metadata.config_defaults,
        "status": version_metadata.status,
        "created_at": version_metadata.created_at
    }
    
    # Cache response
    redis.setex(cache_key, ttl=3600, value=json.stringify(response))
    
    return response
```

### 3.2 List Prompts

**Database Query:**

```sql
SELECT 
    id,
    name,
    description,
    created_at
FROM exp.prompts
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;
```

**Count Query:**

```sql
SELECT COUNT(*) as total
FROM exp.prompts;
```

### 3.3 List Versions of a Prompt

**Database Query:**

```sql
SELECT 
    pv.id,
    pv.version,
    pv.file_path,
    pv.model_provider,
    pv.model_name,
    pv.config_defaults,
    pv.status,
    pv.created_at
FROM exp.prompt_versions pv
WHERE pv.prompt_id = $1
  AND ($2 IS NULL OR pv.status = $2)
ORDER BY pv.version DESC
LIMIT $3 OFFSET $4;
```

**Note:** Content is not loaded for list endpoints (only metadata). Content is loaded on-demand when retrieving a specific version.

---

## 4. Caching Strategy

### 4.1 Cache Key Format

```
prompt_version:{prompt_version_id}
```

### 4.2 Cache Value

```json
{
  "id": "uuid",
  "prompt_id": "uuid",
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
  "status": "active",
  "created_at": "2025-01-15T10:00:00Z",
  "cached_at": "2025-01-15T11:00:00Z"
}
```

### 4.3 TTL Strategy

| Scenario | TTL |
|----------|-----|
| Normal | 1 hour |
| High traffic | 15 minutes |
| After prompt update | Invalidate specific version |

### 4.4 Cache Invalidation

```pseudo
function invalidate_prompt_version_cache(prompt_version_id):
    """
    Invalidate cache for a specific prompt version.
    Called when prompt file is updated or version status changes.
    """
    cache_key = f"prompt_version:{prompt_version_id}"
    redis.delete(cache_key)

function invalidate_prompt_cache(prompt_id):
    """
    Invalidate all versions of a prompt.
    Called when prompt is deleted or renamed.
    """
    # Get all version IDs for this prompt
    version_ids = db.query(
        "SELECT id FROM exp.prompt_versions WHERE prompt_id = $1",
        prompt_id
    )
    
    # Delete cache entries
    for version_id in version_ids:
        cache_key = f"prompt_version:{version_id}"
        redis.delete(cache_key)
```

### 4.5 Cache Warming

```pseudo
function warm_cache_for_active_versions():
    """
    Pre-load cache for active prompt versions.
    Can be run periodically or on service startup.
    """
    active_versions = db.query(
        """
        SELECT id FROM exp.prompt_versions 
        WHERE status = 'active'
        ORDER BY created_at DESC
        LIMIT 100
        """
    )
    
    for version_id in active_versions:
        try:
            # This will populate cache
            get_prompt_version(version_id)
        except Exception as e:
            log_error("Cache warming failed", version_id=version_id, error=str(e))
```

---

## 5. Database Schema Usage

### 5.1 Tables Accessed

| Table | Access Pattern |
|-------|----------------|
| `exp.prompts` | Read by name, read by ID |
| `exp.prompt_versions` | Read by ID, read by prompt_id |

### 5.2 Indexes Required

```sql
-- For prompt lookup
CREATE INDEX idx_prompts_name ON exp.prompts(name);

-- For version lookup
CREATE INDEX idx_prompt_versions_prompt ON exp.prompt_versions(prompt_id);
CREATE INDEX idx_prompt_versions_status ON exp.prompt_versions(status);
CREATE INDEX idx_prompt_versions_provider ON exp.prompt_versions(model_provider, model_name);
```

### 5.3 Query Patterns

**Single Version Lookup:**
- Uses primary key (id) - O(1) lookup
- Joins with prompts table for prompt_name

**List Versions:**
- Uses index on prompt_id
- Optional filter on status (uses status index)
- Pagination with LIMIT/OFFSET

---

## 6. File System Integration

### 6.1 File Path Resolution

```pseudo
function resolve_prompt_file(file_path):
    """
    Resolve relative file path to absolute path.
    Validates path is within repository root.
    """
    repo_root = get_repo_root()  # From environment or config
    absolute_path = os.path.join(repo_root, file_path)
    
    # Normalize path to prevent directory traversal
    absolute_path = os.path.normpath(absolute_path)
    repo_root = os.path.normpath(repo_root)
    
    # Security check: ensure path is within repo root
    if not absolute_path.startswith(repo_root):
        raise SecurityError("File path outside repository root")
    
    return absolute_path
```

### 6.2 File Reading

```pseudo
function read_prompt_file(file_path):
    """
    Read prompt content from file system.
    Handles encoding and errors gracefully.
    """
    absolute_path = resolve_prompt_file(file_path)
    
    try:
        # Read file with UTF-8 encoding
        with open(absolute_path, 'r', encoding='utf-8') as f:
            content = f.read()
        return content
    except FileNotFoundError:
        raise PromptFileNotFoundError(file_path)
    except UnicodeDecodeError:
        raise PromptFileEncodingError(file_path)
    except IOError as e:
        raise PromptFileReadError(file_path, error=str(e))
```

### 6.3 File Path Validation

```pseudo
function validate_file_path(file_path):
    """
    Validate file path format and existence.
    Called when prompt version is created/updated.
    """
    # Check format
    if not file_path.startswith("prompts/"):
        raise ValidationError("File path must start with 'prompts/'")
    
    if not file_path.endswith(".txt"):
        raise ValidationError("File path must end with '.txt'")
    
    # Check file exists
    absolute_path = resolve_prompt_file(file_path)
    if not os.path.exists(absolute_path):
        raise ValidationError(f"Prompt file not found: {file_path}")
    
    # Check file is readable
    if not os.access(absolute_path, os.R_OK):
        raise ValidationError(f"Prompt file not readable: {file_path}")
```

### 6.4 File Watching (Optional)

For production, consider file watching to invalidate cache when files change:

```pseudo
function watch_prompt_files():
    """
    Watch /prompts/ directory for changes.
    Invalidate cache when files are modified.
    """
    # Use file system watcher (e.g., watchdog library)
    watcher = FileSystemWatcher("/prompts/")
    
    def on_file_modified(event):
        if event.is_file and event.src_path.endswith(".txt"):
            # Extract prompt version ID from file path
            # Invalidate cache for that version
            file_path = get_relative_path(event.src_path)
            version_id = get_version_id_from_file_path(file_path)
            invalidate_prompt_version_cache(version_id)
    
    watcher.on_modified = on_file_modified
    watcher.start()
```

---

## 7. Error Handling

### 7.1 Error Categories

| Category | Response | Action |
|----------|----------|--------|
| Validation error | 400 | Return error details |
| Prompt version not found | 404 | Return not found error |
| Prompt file not found | 500 | Log error, return internal error |
| Database error | 503 | Retry logic |
| Cache error | N/A | Fallback to database |
| File system error | 500 | Log error, return internal error |

### 7.2 Error Response Format

```json
{
  "error": "not_found",
  "message": "Prompt version not found",
  "prompt_version_id": "770e8400-e29b-41d4-a716-446655440002"
}
```

### 7.3 Retry Strategy

```pseudo
# Database retry
max_retries = 3
backoff_base = 100ms

for attempt in range(max_retries):
    try:
        return execute_query(...)
    except DatabaseError:
        sleep(backoff_base * (2 ** attempt))

raise ServiceUnavailable()
```

### 7.4 File System Error Handling

```pseudo
function get_prompt_version_with_fallback(prompt_version_id):
    """
    Get prompt version with graceful file system error handling.
    """
    try:
        return get_prompt_version(prompt_version_id)
    except PromptFileNotFoundError as e:
        # Log error
        log_error("Prompt file not found", 
                  prompt_version_id=prompt_version_id,
                  file_path=e.file_path)
        
        # Return metadata without content
        metadata = get_prompt_version_metadata(prompt_version_id)
        return {
            **metadata,
            "content": None,
            "content_error": "Prompt file not found"
        }
    except PromptFileReadError as e:
        # Log error
        log_error("Prompt file read error",
                  prompt_version_id=prompt_version_id,
                  error=str(e))
        
        # Return error response
        raise InternalError("Failed to read prompt file")
```

---

## 8. Performance Considerations

### 8.1 Expected Latency

| Operation | Target P50 | Target P99 |
|-----------|------------|------------|
| Cache hit | <5ms | <20ms |
| Cache miss (DB + file) | <50ms | <200ms |
| List prompts | <30ms | <100ms |
| List versions | <40ms | <150ms |

### 8.2 Throughput

| Metric | Target |
|--------|--------|
| RPS per instance | 500 |
| Concurrent connections | 50 |

### 8.3 Optimization Strategies

- **Connection pooling** for database
- **Pipeline Redis commands** for batch operations
- **File system caching** at OS level
- **Lazy content loading** for list endpoints (metadata only)
- **Cache warming** for active prompt versions

### 8.4 File System Performance

**Considerations:**

- File system I/O is slower than database queries
- Large prompt files (>100KB) may impact latency
- Consider file system caching (OS-level)
- Monitor file system I/O metrics

**Optimization:**

```pseudo
# Read file with caching hint (if OS supports)
def read_prompt_file_optimized(file_path):
    """
    Read file with OS-level caching hints.
    """
    absolute_path = resolve_prompt_file(file_path)
    
    # Use memory-mapped file for large files
    if os.path.getsize(absolute_path) > 100 * 1024:  # > 100KB
        with open(absolute_path, 'rb') as f:
            # Memory-map file for efficient access
            mmapped = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
            content = mmapped.read().decode('utf-8')
            mmapped.close()
            return content
    else:
        # Small file - regular read is fine
        with open(absolute_path, 'r', encoding='utf-8') as f:
            return f.read()
```

---

## 9. Monitoring

### 9.1 Metrics to Expose

| Metric | Type | Labels |
|--------|------|--------|
| `prompt_requests_total` | Counter | status, endpoint |
| `prompt_latency_seconds` | Histogram | endpoint |
| `cache_hits_total` | Counter | |
| `cache_misses_total` | Counter | |
| `file_reads_total` | Counter | |
| `file_read_errors_total` | Counter | |
| `file_read_latency_seconds` | Histogram | |

### 9.2 Alerting Rules

```pseudo
# High error rate
if error_rate > 1%:
    alert("Prompt service error rate high")

# High latency
if p99_latency > 200ms:
    alert("Prompt service latency degraded")

# File system errors
if file_read_errors_total / file_reads_total > 0.01:
    alert("Prompt file read error rate high (>1%)")
```

---

## 10. Security Considerations

### 10.1 File Path Validation

```pseudo
function validate_file_path_security(file_path):
    """
    Validate file path to prevent directory traversal attacks.
    """
    # Check for directory traversal attempts
    if ".." in file_path:
        raise SecurityError("Invalid file path: contains '..'")
    
    # Check path starts with allowed prefix
    if not file_path.startswith("prompts/"):
        raise SecurityError("File path must start with 'prompts/'")
    
    # Normalize and validate
    normalized = os.path.normpath(file_path)
    if normalized != file_path:
        raise SecurityError("File path contains invalid characters")
    
    # Ensure path is within repo root
    repo_root = get_repo_root()
    absolute_path = os.path.join(repo_root, file_path)
    absolute_path = os.path.normpath(absolute_path)
    
    if not absolute_path.startswith(os.path.normpath(repo_root)):
        raise SecurityError("File path outside repository root")
```

### 10.2 Input Validation

```pseudo
function validate_request(request):
    """
    Validate API request parameters.
    """
    # UUID format validation
    if not is_valid_uuid(request.prompt_version_id):
        raise ValidationError("Invalid UUID format")
    
    # Pagination limits
    if request.limit > 100:
        raise ValidationError("Limit cannot exceed 100")
    
    if request.offset < 0:
        raise ValidationError("Offset cannot be negative")
```

### 10.3 Rate Limiting

```pseudo
# Per-API-key rate limit
limit = 1000 requests per minute per API key

if rate_limiter.exceeded(request.api_key):
    return 429 Too Many Requests
```

---

## 11. Content Loading Strategy

### 11.1 Lazy Loading

Content is loaded **on-demand** only when:
- Retrieving a specific prompt version by ID
- Content is explicitly requested

Content is **not** loaded for:
- List prompts endpoint (metadata only)
- List versions endpoint (metadata only)

### 11.2 Content Caching

Content is cached **with metadata** in Redis:
- Single cache entry per prompt version
- Includes both metadata and content
- TTL: 1 hour (configurable)

### 11.3 Content Size Limits

| Limit | Value | Rationale |
|-------|-------|------------|
| Max file size | 1 MB | Prevent memory issues |
| Max content in response | 1 MB | Prevent large responses |
| Cache entry size | 2 MB | Redis memory management |

```pseudo
function validate_content_size(content):
    """
    Validate prompt content size.
    """
    size_bytes = len(content.encode('utf-8'))
    max_size = 1 * 1024 * 1024  # 1 MB
    
    if size_bytes > max_size:
        raise ValidationError(f"Prompt content exceeds maximum size ({max_size} bytes)")
```

---

## 12. TODO: Implementation Notes

- [ ] Choose web framework (e.g., FastAPI, Express, Go Gin)
- [ ] Implement Redis caching layer
- [ ] Set up connection pooling for database
- [ ] Add Prometheus metrics
- [ ] Configure rate limiting
- [ ] Implement file path validation and security checks
- [ ] Add file system error handling
- [ ] Implement cache warming strategy
- [ ] Add file watching for cache invalidation (optional)
- [ ] Write integration tests
- [ ] Add content size validation

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [API_SPEC.md](API_SPEC.md) | API specification |
| [../../docs/data-model.md](../../docs/data-model.md) | Database schema (section 4) |
| [../../docs/prompts-guide.md](../../docs/prompts-guide.md) | Prompt management guide (coming in Phase 2) |
