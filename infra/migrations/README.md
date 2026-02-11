# Database Migrations

This directory contains PostgreSQL schema migrations managed by [yoyo-migrations](https://ollyp.github.io/yoyo/).

## Usage

### 1. Install Requirements
```bash
pip install -r ../requirements-migrations.txt
```

### 2. Run Migrations
To apply all pending migrations:
```bash
yoyo apply --database postgresql://postgres:postgres@localhost:5432/experimentation_platform ./migrations
```

Or using the config file:
```bash
yoyo apply --config ./yoyo.ini
```

### 3. Create a New Migration
```bash
yoyo new ./migrations -m "description_of_change"
```

## Migration Files
Migration files are SQL scripts named with a prefix like `001_`, `002_`, etc. Yoyo tracks applied migrations in a `_yoyo_migration` table in the database.

## Security Note
The database connection string in `yoyo.ini` uses default credentials. For non-local environments, use environment variables or a secure configuration management system.
