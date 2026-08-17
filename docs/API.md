# Expense Tracker API

Base URL: `/api/v1`. Protected endpoints require `Authorization: Bearer <JWT>`.

## Register

`POST /auth/register`

```json
{"email":"alex@example.com","password":"password123","password_confirmation":"password123"}
```

Returns `201` with `data.user` and `data.token`.

## Login

`POST /auth/login`

```json
{"email":"alex@example.com","password":"password123"}
```

Returns a token expiring in 24 hours. Invalid credentials return `401` without revealing whether the email exists.

## Expenses

`POST /expenses` accepts `amount_cents`, `description`, `spent_on`, `category_id`, and optional `currency` (`USD`). `GET /expenses` supports `category_id`, exact `date` (`YYYY-MM-DD`), `search`, `page`, `per_page`, `sort`, and `direction`. Sorting is allow-listed and `per_page` is capped at 100.

Example:

```http
GET /api/v1/expenses?category_id=1&date=2026-01-05&search=coffee&page=1&per_page=20&sort=amount_cents&direction=desc
```

All expense operations are scoped to the bearer-token user. An expense belonging to another user behaves as not found.

## Summaries

`GET /summaries/monthly?month=2026-01` returns `total_amount_cents`, `currency`, and `expense_count`.

`GET /summaries/categories?month=2026-01` returns a `breakdown` array containing `category_id`, `category`, and `amount_cents`, ordered from highest to lowest spending.

## Errors

Errors have this shape:

```json
{"error":{"code":"validation_failed","message":"Validation failed","details":{"description":["can't be blank"]}}}
```

Common statuses are `400` for malformed filters, `401` for missing/invalid tokens, `404` for missing or unauthorized resources, and `422` for validation failures.
