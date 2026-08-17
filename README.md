# Expense Tracker API

Production-oriented Rails API for personal expense tracking. It uses PostgreSQL, JWT bearer authentication, bcrypt password hashing, ownership-scoped queries, integer cents for money, and JSON request/response envelopes.

## Requirements

- Ruby 3.2+
- Bundler
- PostgreSQL 13+

## Setup

```bash
bundle install
cp .env.example .env
bin/rails db:create db:migrate db:seed
bin/rails server
```

Set `SECRET_KEY_BASE` to a long random value. Configure `DATABASE_HOST`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, and `DATABASE_NAME` for deployment. The development seed creates the five standard categories and `demo@example.com` / `password123`.

Run tests with `bin/rails test`.

## Authentication

Register or log in, then send the returned token on protected requests:

```http
Authorization: Bearer <token>
```

## API

All endpoints are prefixed with `/api/v1`.

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| POST | `/auth/register` | No | Create an account |
| POST | `/auth/login` | No | Get a 24-hour token |
| GET | `/users/me` | Yes | Current user |
| GET | `/categories` | Yes | List reusable categories |
| GET | `/categories/:id` | Yes | Show a category |
| GET/POST | `/expenses` | Yes | List or create own expenses |
| GET/PATCH/PUT/DELETE | `/expenses/:id` | Yes | Read or modify own expense |
| GET | `/summaries/monthly?month=2026-01` | Yes | Monthly total |
| GET | `/summaries/categories?month=2026-01` | Yes | Category breakdown |

Expense amounts use `amount_cents` (for example, `$12.50` is `1250`). List filters include `category_id`, `date` (`YYYY-MM-DD`), and `search`; sorting accepts `sort=spent_on|amount_cents|description|created_at` and `direction=asc|desc`. Pagination accepts `page` and `per_page` (maximum 100).

Responses use `{ "data": ... }`; paginated lists also include `{ "meta": ... }`. Errors use `{ "error": { "code": ..., "message": ..., "details": ... } }`.

## Security and operations

JWTs are signed with `SECRET_KEY_BASE` and expire after 24 hours. All expense reads and writes begin from `current_user.expenses`, preventing IDOR access. Strong parameters, SQL-like escaping, allow-listed sorting, foreign keys, unique indexes, and database amount checks protect data integrity. Production should additionally terminate TLS at the edge, restrict `CORS_ORIGINS` to trusted origins, use managed secret storage, and add rate limiting/observability at the gateway.
