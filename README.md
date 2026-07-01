# flashdrop

**English** · [中文](README.zh-TW.md)

An influencer flash-sale marketplace, built on Rails. A creator opens a store,
links their Instagram, and runs limited-time, limited-quantity drops. Fans land on
a public drop page — countdown, live stock, one-tap checkout — and an **AI
assistant answers their questions about the product**, so the creator doesn't have
to write long copy or sit in a DM inbox. Think Kickstarter urgency without the
progress bar: when the timer's up or the stock's gone, it's gone.

**Live demo**

| | |
|---|---|
| Overview | https://srichsun.github.io/flashdrop/ |
| Storefront | https://merchant-os.onrender.com/s/how-to-beast |
| Admin | https://merchant-os.onrender.com (`owner@example.com` / `password123`) |

> Hosted on Render's free tier — the first request may take ~30s to wake up.

**Test checkout** — both gateways run in test mode:

| Gateway | Test card | Notes |
|---------|-----------|-------|
| Stripe | `4242 4242 4242 4242` | any future expiry · any CVC |
| ECPay (綠界) | `4311 9522 2222 2222` | CVC `222` · future expiry · 3D OTP arrives by real SMS — enter the code you receive |

## Highlights

- **AI customer-service agent** — a from-scratch LLM tool-use loop (Anthropic
  Claude). The model calls tenant-scoped tools to look up order status, live stock,
  and the return policy, then answers in the storefront chat. It's **product-aware**
  (ask "is this still available?" on a drop page and it knows which item), runs in a
  **background job**, and **streams the reply back over Action Cable** so the page
  never blocks. **Read-only by design** — no tool can place an order or issue a
  refund — and cross-store isolation is proven by specs (one store can never read
  another's orders). A loop cap and a graceful fallback keep a misbehaving or
  failing model from hanging the chat.
- **Influencer identity** — each store links a public Instagram profile: handle,
  verified badge, and avatar. The whole header links out to the real IG page.
- **Flash-sale drops** — one product, one page, no cart. Original vs. limited price
  with a discount, a **live countdown** to the sale start/end, remaining stock, and
  a buy action gated on sale status (upcoming / on sale / sold out / ended).

## Features

- **Multi-tenant** stores, isolated at the row level (`acts_as_tenant`).
- **Inventory with oversell protection** — checkout decrements stock under a
  pessimistic lock, covered by a threaded race-condition spec.
- **Order state machine** (AASM): `pending → paid → shipped`.
- **Background job chain** on payment — notify the store, email the buyer, queue
  fulfillment.
- **Checkout with a choice of gateway** — Stripe or ECPay (綠界). Both are hosted
  redirect flows confirmed by a signature-verified webhook; the buyer picks at
  checkout and enters name, email, phone and shipping address.
- **Transactional email** via Resend's HTTP API (order confirmation to the buyer).
- **Product images** on Tigris (S3-compatible) object storage via Active Storage,
  with Russian-doll fragment caching on the storefront.
- **Real-time** — the AI reply and the paid-order dashboard both stream in over
  Turbo Streams + Action Cable.
- **JSON REST API** (`/api/v1`) with JWT auth and rack-attack rate limiting.
- **Observability**: Sentry error tracking + Lograge single-line JSON logs.

## Architecture highlights

- **The agent = LLM + your own tools + a loop.** Tools are plain Ruby methods that
  read this store's data; `acts_as_tenant` scopes every query, so the agent is safe
  by construction. The web request only enqueues a job — the model loop runs off the
  request thread and broadcasts the answer back to the browser.
- **Two ways to resolve the tenant** — the admin uses the logged-in user; the public
  storefront (and the agent) uses the store slug in the URL (`/s/:slug`).
- **Pluggable payments** — create a pending order → redirect to the chosen gateway →
  the gateway calls a webhook → verify the signature (Stripe's signature / ECPay's
  `CheckMacValue`) → `order.pay!`. The browser redirect is never trusted; only the
  verified webhook marks an order paid.
- **Postgres-native infrastructure** — Solid Cache and Solid Cable keep the cache and
  Action Cable in Postgres, so the free tier runs with no Redis.
- **Flash-sale status is computed, not stored** — `upcoming/on_sale/sold_out/ended`
  is a function of the clock and stock, so there's no cron job flipping a column.

## Tech decisions

| Area | Choice | Why not the alternative |
|------|--------|-------------------------|
| AI agent | Anthropic Claude + hand-written tool-use loop | Full control over tools, tenant scoping, and the read-only boundary; the SDK's higher-level runner hides the loop I wanted to own |
| Agent latency | Background job + Action Cable push | A synchronous LLM call would block a web thread for seconds |
| Multi-tenancy | `acts_as_tenant` (row-level) | Schema-per-tenant needs a migration per schema as stores grow |
| Orders | AASM state machine | Explicit, testable states beat a hand-rolled `enum + if` |
| Sale status | Computed on read | Storing it means a scheduler to flip it at the exact second |
| Oversell | Pessimistic lock | Most reliable under high contention; optimistic lock retries a lot |
| Payments | Stripe + ECPay, pluggable | One order/webhook flow behind both; the buyer chooses at checkout |
| Email | Resend HTTP API | Outbound SMTP is blocked on the host |
| Images | Active Storage + Tigris (S3) | The host has no object storage and an ephemeral disk |
| Cache / real-time | Solid Cache + Solid Cable | DB-backed, so no Redis on the free tier |

## Tech stack

Rails 8 · PostgreSQL · **Anthropic Claude (AI agent)** · Hotwire · Devise · Pundit ·
acts_as_tenant · AASM · pg_search · Stripe · ECPay · Resend · Active Storage + Tigris ·
Solid Cache/Cable · JWT · Sentry + Lograge · RSpec · Docker · GitHub Actions · Render

## Engineering

- **Tests**: RSpec + FactoryBot; every feature ships with specs, including a threaded
  oversell race-condition test and cross-store isolation tests on the AI tools.
- **CI** (GitHub Actions): RuboCop, RSpec, Brakeman, bundler-audit, gitleaks, Docker
  build.
- **Observability**: Sentry + Lograge with `request_id` / `tenant_id` / `user_id` on
  every log line.

## Running locally

Requires Ruby 3.4.x and PostgreSQL. The AI agent needs an `ANTHROPIC_API_KEY`.

```bash
bundle install
bin/rails db:prepare   # create the database and load the schema
bin/rails db:seed      # demo data: two influencer stores with drops and orders
export ANTHROPIC_API_KEY=sk-ant-...   # for the customer-service agent
bin/dev                # Rails + Tailwind, then open http://localhost:3000
```

Run the test suite:

```bash
bin/rspec
```

Seeded logins (password `password123`): `owner@example.com`, `staff@example.com`
(**How to Beast** · @howtobeast), `owner2@example.com` (**Wisdm** · @wisdm).

## Deployment

Deployed on Render from `render.yaml` (Docker web service + managed Postgres). The
database seeds itself on boot, so the demo always has data. Set `RAILS_MASTER_KEY`
and `ANTHROPIC_API_KEY` in the host; payment, email and storage credentials are
environment variables (ECPay falls back to its public test credentials).
