# MerchantOS

A multi-tenant e-commerce SaaS — merchants sign up, open a store, and manage
products, inventory and orders; shoppers browse a public storefront, search, and
check out. Think of it as a lightweight Shopify.

**Live demo**

| | |
|---|---|
| Storefront | https://merchant-os.onrender.com/s/demo-store |
| Admin | https://merchant-os.onrender.com (`owner@example.com` / `password123`) |
| Source | https://github.com/srichsun/merchant_os |

> Hosted on Render's free tier — the first request may take ~30s to wake up.

## Features

- **Multi-tenant** stores, isolated at the row level (`acts_as_tenant`).
- **Inventory with oversell protection** — checkout decrements stock under a
  pessimistic lock, covered by a race-condition spec.
- **Order state machine** (AASM): `pending → paid → shipped`.
- **Background job chain** on payment — notify the store, email the buyer, queue
  fulfillment.
- **Product search** with Postgres trigram (`pg_search`), no Elasticsearch.
- **Public storefront** with checkout and **real ECPay (綠界) payment** — redirect
  to ECPay, then a signature-verified webhook marks the order paid.
- **Observability**: Sentry error tracking + Lograge single-line JSON logs.

## Architecture highlights

- **Two ways to resolve the tenant** — the admin uses the logged-in user; the
  public storefront uses the store slug in the URL (`/s/:slug`).
- **Payment flow** — create a pending order → redirect to ECPay → ECPay calls a
  webhook → verify the `CheckMacValue` signature → `order.pay!`. The same shape as
  most hosted gateways, so the integration is transferable.
- **Frontend** — Hotwire for the admin (server-rendered HTML), plus the storefront;
  a single stack, no separate SPA.

## Tech decisions

| Area | Choice | Why not the alternative |
|------|--------|-------------------------|
| Multi-tenancy | `acts_as_tenant` (row-level) | Apartment schema-per-tenant means a migration per schema as stores grow |
| Search | `pg_search` trigram | No need to run an Elasticsearch cluster at this scale |
| Orders | AASM state machine | Explicit, testable states beat hand-rolled `enum + if` |
| Oversell | Pessimistic lock | Most reliable under high contention; optimistic lock retries a lot |
| Payments | ECPay (綠界) | Stripe can't collect for Taiwan merchants; ECPay is the local standard |

## Tech stack

Rails 8 · PostgreSQL · Hotwire · Devise · Pundit · acts_as_tenant · AASM ·
pg_search · Sidekiq · Sentry + Lograge · RSpec · Docker · GitHub Actions · Render

## Engineering

- **Tests**: RSpec + FactoryBot; every feature ships with specs, including a
  threaded oversell race-condition test.
- **CI** (GitHub Actions): RuboCop, RSpec, Brakeman, bundler-audit, gitleaks,
  Docker build.
- **Observability**: Sentry + Lograge with `request_id` / `tenant_id` / `user_id`
  on every log line.

## Running locally

Requires Ruby 3.4.x and PostgreSQL.

```bash
bundle install
bin/rails db:prepare   # create the database and load the schema
bin/rails db:seed      # demo data: two stores with products and orders
bin/dev                # Rails + Tailwind, then open http://localhost:3000
```

Run the test suite:

```bash
bin/rspec
```

Seeded logins (password `password123`): `owner@example.com`, `staff@example.com`
(Demo Store), `owner2@example.com` (Coffee Lab).

## Deployment

Deployed on Render from `render.yaml` (Docker web service + managed Postgres).
The database seeds itself on boot, so the demo always has data. Set
`RAILS_MASTER_KEY` in the host; ECPay defaults to its public test credentials.
