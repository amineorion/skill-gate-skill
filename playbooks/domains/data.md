# data — domain playbook

## Canonical query

```
/v1/search?domain=data&sort=score
```

Triggers: `has_db_migrations=true`, deps include `prisma`, `drizzle-orm`,
`typeorm`, `mongoose`, `sqlalchemy`, `alembic`, `pandas`, `polars`,
`duckdb`, `clickhouse`, `dbt`; behavior mentions "sql", "migration",
"schema", "etl", "pipeline", "warehouse".

## Top skills

1. `/sql-migrate` — drafts SQL migrations from prose, flags locking issues, suggests backfill strategies.
2. `/schema-review` — pre-merge review of schema changes, NULL/NOT-NULL rules, indexes.
3. `/cron-jobs` — validates cron expressions, checks DST, dedupes against the existing schedule.
4. `/etl-trace` — traces a row's path through pipelines to locate where data went wrong.

## When-to-use lines

- `/sql-migrate` — "When you want to add a column to a 50M-row table without breaking prod."
- `/schema-review` — "Before merging migration PRs — checks index + locking + backfill safety."
- `/cron-jobs` — "When you're scheduling a recurring job and need a cron expression that won't double-run on DST."

## Anti-patterns

- Don't recommend `/etl-trace` to a project without a pipeline (no
  airflow/dbt/dagster/luigi/temporal markers).
- Data-skill installs should usually be paired with `/review` so PRs
  touching schema get the right second-pair-of-eyes.
