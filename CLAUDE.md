# MerchantOS

A multi-tenant e-commerce backend SaaS, like a lightweight Shopify. A merchant
signs up, gets their own store, and manages products, orders, inventory, and members.

## Tech choices (settled — don't swap without discussion)

| Area | Choice |
|------|--------|
| Multi-tenancy | acts_as_tenant, row-level (`tenant_id` + default scope); schema isolation as a scale option |
| Products & inventory | Pessimistic lock (`with_lock`) + rack-attack |
| Orders | AASM state machine |
| Payments | Stripe (international) + ECPay (Taiwan) + async webhook |
| Search | pg_search (Postgres full-text, Chinese bigram); ES as a scale option |
| Real-time notifications | Turbo Streams + ActionCable (Redis already in use) |
| Background jobs | Sidekiq |
| Reports / analytics | Postgres window functions |
| Members / permissions | Devise (authentication) + Pundit (authorization) |
| REST API | REST + JWT + rack-attack |
| Product page cache | Rails fragment caching (Russian doll) + Redis store |
| Performance | bullet for N+1 + `includes` preload + `EXPLAIN`/indexes |

Not in the core feature list (from other parts of the plan):

| Area | Choice |
|------|--------|
| Frontend | Hotwire (admin HTML) + REST API (external JSON) |
| Deploy | Docker + GitHub Actions → Fly.io |
| Observability | Sentry + Lograge |

## Conventions

- Tests: RSpec + FactoryBot (not minitest / fixtures). **All code ships with its
  tests in the same change** — never a later phase. High-risk paths get a targeted
  spec (e.g. the oversell path must have a race-condition spec).
- Code style: rubocop-rails-omakase.
- Migrations: strong_migrations blocks risky operations.
- N+1: catch with bullet in development; fix with `includes` / `preload`.
- Commit messages: English, conventional-commit prefix (`feat:`/`fix:`/`chore:`/
  `refactor:`/`test:`/`docs:`), short and plain.
- Code comments: English, plain wording — explain the why, skip the obvious what.
- Add a feature-specific gem only when its step arrives; don't pre-stack the Gemfile.

## Roadmap

**Foundation**

1. [x] App scaffold (rails new, Docker, RSpec / RuboCop / Gemfile)
2. [ ] CI (GitHub Actions: lint + test)
3. [ ] Auth + multi-tenancy + authorization skeleton (Devise + acts_as_tenant + Pundit)
4. [ ] Walking skeleton deployed to Fly.io
5. [ ] README

**Core**

6. [ ] Products + inventory (oversell protection, race-condition spec)
7. [ ] Order state machine (AASM)
8. [ ] Sidekiq job chain (paid → decrement stock → notify → ship, each step retries)
9. [ ] Seed data
10. [ ] Sentry + Lograge

**Extras**

11. [ ] Payments (Stripe + ECPay; can start mocked)
12. [ ] pg_search full-text search (Chinese bigram)
13. [ ] Turbo Streams + ActionCable real-time notifications
14. [ ] Caching (fragment / Russian doll + Redis)
15. [ ] REST API + JWT + rack-attack rate limiting
16. [ ] Performance tuning (bullet for N+1, indexes, EXPLAIN)
