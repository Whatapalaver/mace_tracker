# Mace/Kettlebell Session Tracker — Context Doc

## Purpose

A Rails app to log strength-conditioning training sessions (mace, kettlebell, etc.)
across variable protocols — interval work, fixed-reps-for-time, EMOM — and chart
progression over time. Core design goal: session *shapes* (protocols) are
user-definable templates, not hardcoded types, so new training formats can be
added without code changes to the core engine.

## Tech stack

- Rails 8.x
- **SQLite** (production-supported in Rails 8; single-user app, no need for a
  hosted Postgres cluster — minimises cost). Litestream or Fly volume snapshots
  for backup.
- ViewComponent for chart/card components
- Hotwire (Turbo Frames + Stimulus) for shape-based dynamic forms and chart filtering
- Tailwind
- RSpec + FactoryBot
- Chartkick + Chart.js (or ApexCharts) for charts
- Fly.io deploy

## Core concept: Session Shapes are templates

A **Session Shape** defines which variables a protocol uses and which outputs
get computed from them. Shapes are **exercise-agnostic** — a shape like
"interval work" is reusable across 10-2, 360 single arm, 360 double arm,
kettlebell swings, etc. `Session` links an `Exercise` and a `SessionShape`
together; the exercise and the shape used for it can change over time.

Three shapes to build initially:

1. **Interval work** (work/rest sets) — e.g. "5 min work, 10 min rest, 10kg, 5 sets"
2. **Fixed reps for time** — e.g. "100 reps at 10kg, timed"
3. **EMOM** (simplified) — e.g. "20 reps every minute at 10kg until failure"

New shapes should be addable via data (seeds/admin), not new model classes,
wherever the output formulas are generic enough to support it.

## Variable taxonomy

Every variable used by a shape is classified on two independent axes:

- **Level**: `session` (one value for the whole session) vs `set` (varies per set)
- **Nature**: `planned` (prescribed before starting) vs `measured` (what actually happened)

This split applies uniformly — not just to rest, but to weight and work duration
too, since any of them can drift from the plan mid-session (e.g. dropping weight,
running over on rest).

| Variable | Level | Planned | Measured |
|---|---|---|---|
| Weight | session (default) / set (override) | `planned_weight_kg` | `weight_kg` (per set, only if it deviates) |
| Work duration | session | `planned_work_seconds` | `duration_seconds` (per set, interval work) |
| Rest duration | session | `planned_rest_seconds` | `rest_seconds_actual` (per set) |
| Sets | session | `planned_sets` | (implicit: count of SessionSet rows) |
| Target reps | session | `target_reps` | — |
| Reps | set | — | `reps` (measured, per set) |
| Heart rate | set | — | `heart_rate_avg`, `heart_rate_end` (optional, future wearable integration) |

Storing both planned and actual is intentional — it enables an **adherence
metric** later (`actual − planned`, e.g. "am I really resting 5 min or drifting
to 6?") at no extra schema cost, even if we don't build that chart in v1.

## Output taxonomy

Outputs are computed values used for charting. Every output has:

- **Formula** — expressed over the variables above
- **Scope** — `per_set`, `per_session` (aggregated across a session's sets), or
  `cumulative` (rolls up across many sessions over time — a running total, not
  a trend line)
- **Direction** — `higher_is_better` or `lower_is_better`
- **Comparability key** — the set of variables that must match between two data
  points for a chart to compare them meaningfully. Always includes
  `exercise + session_shape` at minimum, plus whichever shape-specific variables
  are relevant (e.g. weight, work_duration).

### Per-shape output definitions

**Interval work**
| Output | Formula | Scope | Comparability key |
|---|---|---|---|
| Pace | `reps / duration_seconds` | per_set | exercise, shape, weight, work_duration |
| Best pace | `max(set.pace)` | per_session | same as above |
| Avg pace | `mean(set.pace)` | per_session | same as above |
| Total session output | `Σ(reps × weight)` | per_session | exercise, shape |
| Output per total time | `Σ(reps × weight) / (work + rest time)` | per_session | exercise, shape, weight |
| Output per working time | `Σ(reps × weight) / (work time only)` | per_session | exercise, shape, weight |

Pace chart should support toggling between best-set and average-across-sets
(both computed and available; not a single default). "1/3/5 min sets" are
filtered as distinct series (different `work_duration`), never averaged together.

**Fixed reps for time**
| Output | Formula | Scope | Comparability key |
|---|---|---|---|
| Time | `duration_seconds` | per_session | exercise, shape, weight, target_reps |
| Pace | `reps / duration_seconds` | per_session | exercise, shape, weight, target_reps |

**EMOM (simplified)**
Deliberately minimal — time-within-the-minute isn't reliably trackable, so the
only scored output is:

| Output | Formula | Scope | Comparability key |
|---|---|---|---|
| Total sets completed | `count(sets before failure)` | per_session | exercise, shape, weight, target_reps_per_minute |

No per-set output needed for EMOM — reps/minute is prescribed and constant.

### Cumulative (lifetime) outputs

Separate from progression charts — monotonic running totals, filterable by exercise:

- `total_reps` — Σ reps across all sessions (optionally filtered by exercise)
- `total_volume` — Σ(reps × weight) across all sessions

These get their own chart type (climbing line), distinct from the
attempt-over-attempt trend lines above.

## Benchmarks

Some sessions are deliberate all-out monthly tests (e.g. "3 sets of 5 min" or
"10 sets of 2 min") rather than regular training. Mixing these with submaximal
training days in a progression chart creates a false/noisy trend.

**Decision: BenchmarkPreset (Option B)** — a saved, reusable protocol
definition (shape + exercise + weight + work/rest/sets all pre-filled) that can
be selected when logging a benchmark session. This guarantees the
comparability key matches every time you repeat the test, and gives a one-tap
way to start a monthly benchmark without re-entering config.

- `Session belongs_to :benchmark_preset, optional: true`
- `Session#is_benchmark` boolean, derived from presence of `benchmark_preset_id`
  (or explicit flag if a one-off all-out effort doesn't warrant a saved preset)
- All progression charts get an implicit "benchmarks only" filter toggle,
  **off by default** (so regular training data still populates trend/volume
  charts), on when a clean max-effort-only comparison is wanted.

## Schema sketch (indicative, not final migrations)

```
exercises
  - name
  - arm (single/double/n_a)
  - notes

session_shapes
  - name (interval_work / fixed_reps_for_time / emom)
  - description

benchmark_presets
  - name (e.g. "Monthly 3x5")
  - exercise_id
  - session_shape_id
  - planned_weight_kg
  - planned_work_seconds
  - planned_rest_seconds
  - planned_sets
  - target_reps / target_reps_per_minute

sessions
  - date
  - exercise_id
  - session_shape_id
  - benchmark_preset_id (nullable)
  - is_benchmark (boolean)
  - planned_weight_kg
  - planned_work_seconds
  - planned_rest_seconds
  - planned_sets
  - target_reps
  - target_reps_per_minute
  - rpe_session (optional)
  - notes

session_sets
  - session_id
  - set_number
  - reps
  - weight_kg (override; nullable — falls back to session's planned_weight_kg)
  - duration_seconds
  - rest_seconds_actual
  - heart_rate_avg (nullable, future)
  - heart_rate_end (nullable, future)
```

Output calculations should live in plain Ruby service objects / POROs per shape
(e.g. `Progression::IntervalWorkCalculator`), not scattered across views or
buried in model callbacks — keeps them independently testable in RSpec and
keeps `SessionShape`-specific logic isolated (STI or a strategy-object pattern
per shape, decide at implementation time based on how much branching the
calculators actually need).

## Coach sharing (build now)

Needed immediately, even though the app is single-user. Coach does **not**
need an account — a token-based read-only share link is the right amount of
friction (none).

```
share_links
  - token (random, url-safe, indexed)
  - scope (e.g. "all", or exercise_id/session_shape_id/date_range filters)
  - expires_at (nullable — permanent or time-boxed)
```

A share link renders a read-only version of the dashboard/charts filtered by
its scope. No login flow for the coach; link can be regenerated/revoked at
any time by deleting/rotating the token.

## Explicitly out of scope for v1

- Wearable data ingestion (HR fields exist in schema but no Whoop/Oura/Apple
  Watch integration yet)
- Adherence metric charts (planned vs actual) — schema supports it, chart not built yet
- New session shapes beyond the three above (schema/engine should support
  adding them without core changes, but no UI for user-defined shape creation in v1)

## Future development: multi-tenancy (not built in v1)

**Decision: build single-user for now.** This section documents the direction
so implementation choices in v1 don't accidentally make a future multi-tenant
migration harder than it needs to be.

**What "sharing" means, clarified:**
1. Other people tracking their own workouts using this tool (separate concern from coach sharing)
2. Sharing your own results/analysis with your coach (**this one is v1** — see Coach Sharing above)

If (1) is pursued later:

- Add a `User` model; `Session`, `SessionSet`, and `BenchmarkPreset` gain a
  `user_id` and all queries get scoped to `current_user`. This is a
  straightforward migration (Rails handles adding a column + backfilling +
  scoping cleanly) and is **not** a reason to add `user_id` speculatively now
  — do it when actually needed.
- **Exercises and Session Shapes should be seeded as global defaults, with
  per-user custom additions layered on top** (confirmed direction). Practically:
  `exercises` and `session_shapes` get a nullable `user_id` — `null` means a
  global/system default visible to everyone, a populated `user_id` means a
  user-specific custom addition. This is the one schema decision worth being
  deliberate about even in v1: **seed data should go in as global records
  (`user_id: nil`) from the start**, rather than implicitly "owned" by whichever
  single user exists today, so the global-vs-custom split doesn't require
  reclassifying existing rows later.
- Scale point: SQLite remains fine for a handful of users each logging
  occasionally. The trigger for reconsidering the database engine is
  concurrent multi-instance write load, not simply "more than one user" — a
  scale this app is unlikely to reach without becoming a much bigger product.
  If/when that trigger is hit, Postgres is the natural target (already used
  in other projects), not MySQL.
- Avoid raw SQL / DB-specific functions in scopes and calculators throughout
  v1 — keeps a future engine swap (SQLite → Postgres) to a data export/reload
  rather than a query rewrite.

## Open questions for implementation

- STI vs single `Session` model + enum + strategy object for shape-specific behaviour
- Whether output values are computed on read or persisted/cached per session
- Chart library choice (Chartkick/Chart.js vs ApexCharts) — no strong preference stated yet