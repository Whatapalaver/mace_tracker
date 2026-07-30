# Build Plan

Living checklist of where this project stands. Updated in the same commit as
the work that completes each item — if a box is checked, `bundle exec rspec`
passes as of that commit. Full design rationale lives in `context.md`.

Mobile-first UI throughout (logging happens on a phone; desktop is for stats
review). PWA support is "installable shell only" (manifest/icons/service
worker, no offline data queue) — wired up after Phase 2.

## Phase 0 — App skeleton & tooling
- [x] Rails 8 app generated (SQLite, Tailwind, no Minitest)
- [x] RSpec, FactoryBot, Shoulda Matchers, ViewComponent, Chartkick installed
      and wired up (importmap pins, `spec/support/*`)
- [x] Turbo, Stimulus, Tailwind build pipeline confirmed working (`bin/dev`)
- [x] `BUILD_PLAN.md` committed alongside skeleton

## Phase 1 — Core schema & models (no UI)
- [x] `Exercise` (name, arm enum, notes, nullable user_id) + spec
- [x] `SessionShape` (name, description, nullable user_id) + seeds for the
      three shapes + spec
- [x] `Session` (planned_* fields, shape-conditional validations) + spec
- [x] `SessionSet` (reps, weight override, durations) + spec

## Phase 2 — Interval work vertical slice
- [x] `Progression::BaseCalculator` + `Progression::Calculator.for(session)`
      factory + spec
- [x] `Progression::IntervalWorkCalculator` (pace, best/avg pace, total
      output, output per total/working time) + spec
- [x] `SessionsController` + `SessionSetsController` (interval_work only) +
      request specs
- [x] Session show view (ViewComponent) rendering computed outputs + spec
- [x] Chartkick progression chart (best-vs-avg pace toggle) filtered by
      comparability key

## Phase 2b — PWA installable shell
- [x] Manifest + icons + service worker routes uncommented; installable to
      home screen (online-required, no offline queue)

## Phase 3 — Remaining two shapes
- [x] `fixed_reps_for_time`: validations + `Progression::FixedRepsForTimeCalculator`
      + spec
- [x] `emom`: validations + `Progression::EmomCalculator` + spec
- [x] Shape-aware session form (Stimulus) + system spec across all 3 shapes

## Phase 4 — Cumulative (lifetime) outputs
- [x] `Progression::LifetimeStats` (total_reps, total_volume) + spec + chart

## Phase 5 — Benchmarks
- [x] `BenchmarkPreset` model + spec
- [x] `Session#is_benchmark` derivation (preset-driven + explicit override) +
      spec
- [x] "Start from preset" flow + benchmarks-only chart filter (off by
      default) + feature spec

## Phase 6 — Coach sharing
- [x] `ShareLink` model (token, scope, expires_at) + spec
- [x] Public read-only dashboard controller scoped by share link + request
      specs
- [x] UI to create/regenerate/revoke share links

## v1 feature set complete

All six phases above are done: three session shapes end-to-end (model to
chart), lifetime cumulative stats, benchmark presets with a start-from-preset
flow and benchmarks-only chart filter, an installable mobile-first PWA shell,
and token-based read-only coach sharing. 150 passing specs (model, request,
component, service, and system specs with headless Chrome), clean rubocop.

## Explicitly deferred (see context.md)
- Wearable/HR ingestion, adherence (planned vs actual) charts, user-defined
  shape creation UI, offline PWA logging, Fly.io deploy
- Coach-sharing scope filtering: the `scope` JSON column can hold
  session_shape/date_range filters too, but only the exercise filter has UI
  in v1
