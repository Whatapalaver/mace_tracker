# Warrior Tracker

A personal training log and progression tracker for mace and kettlebell work, built around the
way this training is actually described and compared: algebraic interval/rep notation (e.g.
`5(5mw+5mr)` for five sets of 5 minutes work/5 minutes rest, or a bare `100, 100, 50` for
straight sets) rather than generic "sets x reps x weight" fields.

Currently deployed at **[mace-tracker.fly.dev](https://mace-tracker.fly.dev/)**.

## What it does

- **Log a session** in one step: pick an exercise, type its shape/signature, a weight, and the
  reps you actually did (comma-separated — one value per set, with an optional per-set weight
  override like `100@6, 100@6, 50@8` for sessions with no consistent weight). Shape
  (interval work vs. straight sets) is inferred from what you type; a collapsed "different
  shape" section covers the rarer fixed-reps-for-time/EMOM cases via a short two-step formula +
  review flow.
- **Equipment, Exercises, and Tools**: exercises belong to a piece of equipment (e.g. Mace,
  Kettlebell); Tools let you optionally tag a session with the *specific* physical implement used
  (e.g. "Mace: Eryx Adjustable" vs. "Mace: Wrecking Ball") for finer-grained comparison later.
- **Stats and progression**: lifetime totals, reps/volume by day/week/month/year, personal bests
  per weight (with lighter weights dropped once a heavier one already matches or beats their
  total volume), and a signature browser that compares sessions either by their *exact* shape or
  — for interval work — by set duration alone, so you can see every "5 minutes of work" effort
  regardless of how many sets it was part of.
- **Benchmark presets**: save a named formula (e.g. "5x5") to quickly log or compare against later.
- **Share links**: generate a read-only, token-based link (optionally scoped to one exercise) that
  gives a coach or training partner the same stats/history views, filters included, with no
  login and no edit access.
- **Bulk import**: `lib/tasks/historic_sessions.rake` and `lib/tasks/hevy_import.rake` for
  one-time backfills of pre-existing training history.

## Tech stack

- Ruby 3.4.10, Rails 8.1
- SQLite (via Rails 8's multi-database setup: primary/cache/queue/cable)
- Hotwire (Turbo + Stimulus), Tailwind CSS v4 (via the `tailwindcss-rails` gem, not npm)
- RSpec, FactoryBot, Capybara + Selenium (headless Chrome) for system specs
- Deployed on Fly.io via Docker (Thruster in front of Puma)

## Local development

```bash
bin/setup     # bundle install + db:prepare + clear logs/tmp
bin/dev       # Rails server + Tailwind watcher (foreman, via Procfile.dev)
```

The app is then at `http://localhost:3000`. No login is required locally (see
[Authentication](#authentication) below), and `bin/setup`'s `db:prepare` seeds the exercises/shapes
the app expects on that first, fresh database creation.

Useful rake tasks in development:

```bash
bin/rails demo:seed   # a small amount of fake session history to look at locally (dev/test only)
```

### Running tests and lint

```bash
bundle exec rspec       # full test suite
bundle exec rspec spec/path/to/file_spec.rb        # a single file
bundle exec rspec spec/path/to/file_spec.rb:42     # a single example by line
bundle exec rubocop     # style/lint (rubocop-rails-omakase)
bin/brakeman            # static security scan
bin/bundler-audit       # gem vulnerability scan
```

CI (`.github/workflows/ci.yml`) runs Brakeman, bundler-audit, an importmap audit, and RuboCop on
every push/PR — it does not currently run the RSpec suite, so run it locally before pushing.

## Authentication

The whole app sits behind a single shared HTTP Basic Auth username/password
(`ApplicationController#authenticate_owner!`), since it's a single-user personal tracker rather
than a multi-account app. That check is a no-op unless `BASIC_AUTH_USER`/`BASIC_AUTH_PASSWORD`
are actually set (via Fly secrets in production), so local development and tests need no login at
all.

The one deliberate exception is **share links**: `SharedDashboardsController` skips
`authenticate_owner!` entirely, since those pages are meant to be reachable by anyone holding the
unguessable per-link token, without needing the owner's credentials.

## Deployment

Deployed to [Fly.io](https://fly.io) as app `mace-tracker` (the Fly app name predates the
"Warrior Tracker" rebrand and was deliberately left alone rather than risk the live URL/volume —
see `fly.toml`).

- **Automatic**: `.github/workflows/fly-deploy.yml` runs `flyctl deploy --remote-only` on every
  push to `main`.
- **Manual**: `fly deploy` from a checkout with `flyctl` installed and authenticated.
- **One-off commands against the live app** (console, data imports, maintenance): trigger the
  `.github/workflows/fly-run.yml` workflow from the Actions tab ("Fly Run Command"), which wakes
  the machine (it scales to zero when idle) and runs the given command via `flyctl ssh console`.
  Useful for things like `bin/rails hevy:import` without needing local network access to Fly.

The production image is built from the `Dockerfile` (gems → asset precompile, which builds
Tailwind's CSS via the `tailwindcss-rails` gem's hook → Thruster in front of Puma, bound to the
port set by `HTTP_PORT` in `fly.toml`'s `[env]`), with the SQLite databases
persisted on a Fly volume mounted at `/data`.
