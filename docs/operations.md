# Operations Runbook

One page for "what runs where, what it needs, and where to look when it breaks."
The goal is not to merge tools into one platform, but to keep the knowledge,
configuration, and alerts in one place.

## Architecture at a glance

The app is a single Rails service on Render with one managed Postgres. Everything
else is an external dependency wired in through environment variables.

| Plane | Tools | Role |
|-------|-------|------|
| Deploy + config | GitHub (code + Actions) → Render (runtime + env vars) | One path into production |
| Data / storage | Postgres (Render), Tigris (images), SMTP provider (email) | External deps, configured via env |
| Observability | Sentry (errors), Render logs + Lograge (logs), UptimeRobot (uptime) | Where to look when something breaks |

- **App**: <https://merchant-os.onrender.com> — storefront `/s/demo-store`, admin login `owner@example.com` / `password123`.
- **Region**: Singapore (web + database).
- **Tier**: Render free (single instance, no zero-downtime deploys), free Postgres.

## Services

| Service | Role | Dashboard | Notable free-tier limits |
|---------|------|-----------|--------------------------|
| Render | Web host (Docker) + managed Postgres | render.com | 1 instance, spins down when idle, 1 GB DB |
| Tigris | Object storage for product images (S3-compatible) | console.tigris.dev | No egress fees; endpoint differs per bucket |
| SMTP (SendGrid) | Transactional email (order notifications) | app.sendgrid.com | ~100 emails/day; sender must be verified |
| Sentry | Error tracking | sentry.io | Limited monthly events |
| UptimeRobot | Uptime check + keep-warm ping on `/up` every 5 min | uptimerobot.com | 5-min interval |
| GitHub Actions | CI: scan, lint, test, docker build | github.com (Actions tab) | — |

## Environment variables

All secrets live in **Render → service → Environment** (single source of truth).
Secrets must never be committed. `*` marks a secret.

### Required

| Variable | What it is |
|----------|------------|
| `RAILS_MASTER_KEY` * | Decrypts credentials / derives `secret_key_base`. Value = `config/master.key`. |
| `DATABASE_URL` | Postgres connection string. Injected by Render from the managed DB. |
| `PORT` | Thruster listens here; set to `80` (matches the Dockerfile). |

### Images (Tigris) — without these, storage falls back to the local disk

| Variable | What it is |
|----------|------------|
| `AWS_ACCESS_KEY_ID` * | Tigris access key id |
| `AWS_SECRET_ACCESS_KEY` * | Tigris secret (shown once at creation) |
| `AWS_ENDPOINT_URL_S3` | Tigris API URL, e.g. `https://t3.storage.dev` (check the bucket — can also be `https://fly.storage.tigris.dev`) |
| `BUCKET_NAME` | The bucket name |
| `ACTIVE_STORAGE_SERVICE` | Optional override: force `tigris` or `local` |

### Email (SMTP) — without these, mail delivery is skipped (no crash)

| Variable | What it is |
|----------|------------|
| `SMTP_ADDRESS` | e.g. `smtp.sendgrid.net` |
| `SMTP_PORT` | `587` |
| `SMTP_USERNAME` | e.g. `apikey` for SendGrid |
| `SMTP_PASSWORD` * | API key / SMTP password |
| `MAIL_FROM` | Verified sender, e.g. `MerchantOS <no-reply@…>` |
| `APP_HOST` | Host used in mailer links, e.g. `merchant-os.onrender.com` |

### Optional

| Variable | What it is |
|----------|------------|
| `SENTRY_DSN` * | Enables Sentry error reporting (production only) |
| `ECPAY_MERCHANT_ID` / `ECPAY_HASH_KEY` * / `ECPAY_HASH_IV` * / `ECPAY_CHECKOUT_URL` | Real ECPay credentials; defaults are ECPay's shared test merchant |
| `RAILS_LOG_LEVEL` | Defaults to `info` |
| `SKIP_DB_PREPARE` | Set to `true` to skip boot-time `db:prepare` / `db:seed` for a one-off deploy |

## Deploy

**Single path: push to `main` → Render auto-deploys** (Render watches the repo;
config in `render.yaml`). GitHub Actions runs CI on the same push (scan / lint /
test / docker build); it is *not* the deploy path (the `flyctl` deploy job stays
dormant unless `FLY_API_TOKEN` is set).

On each boot the container runs (see `bin/docker-entrypoint`):

1. `bin/rails db:prepare` — create the DB if needed, run pending migrations.
2. `bin/rails db:seed` — idempotent demo data top-up.

**Rollback**: Render → service → Deploys → pick the last good deploy → Rollback.
Because the free tier has a single instance and no zero-downtime deploy, a deploy
that fails to boot takes the site down until it is rolled back or fixed forward.

## Observability — where to look

- **Errors** → Sentry (`SENTRY_DSN`). Tagged with `tenant_id` and `user_id`.
- **Logs** → Render → service → Logs. One JSON line per request via Lograge,
  carrying `request_id`, `tenant_id`, `user_id`.
- **Uptime** → UptimeRobot pings `/up` every 5 minutes (also keeps the free
  instance warm). `/up` returns 200 only if the app boots cleanly.

**Alerting**: point Sentry and UptimeRobot at the same email / Slack channel so
"something is wrong" arrives in one place.

Deliberately *not* used at this scale: Prometheus / Grafana / Datadog APM / ELK /
k8s. Errors + logs + uptime, each one tool, is enough here.

## Known gotchas (learned the hard way)

- **Tigris endpoint must match the bucket.** A bucket on `t3.storage.dev` will not
  work against `fly.storage.tigris.dev`. Symptom: storage init fails / 500s.
- **One database for everything skips the Solid schemas.** Cache / queue / cable
  connections share the single Postgres, so `db:prepare` only loads the primary
  `schema.rb` — the `solid_cache_entries` / `solid_cable_messages` tables are
  created by an explicit migration instead (`db/migrate/*_create_solid_cache_and_cable_tables.rb`).
- **Free tier = single instance.** A failed deploy can briefly take the live site
  down (no old instance kept serving). Roll back to recover fast.
- **Background jobs run with `:async`**, not Sidekiq — the free tier has no Redis
  or worker. Jobs run in-process; fine for a demo, revisit before real load.
- **ECPay stage is flaky.** The shared test merchant returns intermittent 500s.
  Real payments need your own ECPay merchant credentials in the env vars above.
