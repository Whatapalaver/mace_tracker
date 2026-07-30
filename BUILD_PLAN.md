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
- [ ] `SessionShape` (name, description, nullable user_id) + seeds for the
      three shapes + spec
- [ ] `Session` (planned_* fields, shape-conditional validations) + spec
- [ ] `SessionSet` (reps, weight override, durations) + spec

## Phase 2 — Interval work vertical slice
- [ ] `Progression::BaseCalculator` + `Progression::Calculator.for(session)`
      factory + spec
- [ ] `Progression::IntervalWorkCalculator` (pace, best/avg pace, total
      output, output per total/working time) + spec
- [ ] `SessionsController` + `SessionSetsController` (interval_work only) +
      request specs
- [ ] Session show view (ViewComponent) rendering computed outputs + spec
- [ ] Chartkick progression chart (best-vs-avg pace toggle) filtered by
      comparability key

## Phase 2b — PWA installable shell
- [ ] Manifest + icons + service worker routes uncommented; installable to
      home screen (online-required, no offline queue)

## Phase 3 — Remaining two shapes
- [ ] `fixed_reps_for_time`: validations + `Progression::FixedRepsForTimeCalculator`
      + spec
- [ ] `emom`: validations + `Progression::EmomCalculator` + spec
- [ ] Shape-aware session form (Stimulus) + system spec across all 3 shapes

## Phase 4 — Cumulative (lifetime) outputs
- [ ] `Progression::LifetimeStats` (total_reps, total_volume) + spec + chart

## Phase 5 — Benchmarks
- [ ] `BenchmarkPreset` model + spec
- [ ] `Session#is_benchmark` derivation (preset-driven + explicit override) +
      spec
- [ ] "Start from preset" flow + benchmarks-only chart filter (off by
      default) + feature spec

## Phase 6 — Coach sharing
- [ ] `ShareLink` model (token, scope, expires_at) + spec
- [ ] Public read-only dashboard controller scoped by share link + request
      specs
- [ ] UI to create/regenerate/revoke share links

## Explicitly deferred (see context.md)
- Wearable/HR ingestion, adherence (planned vs actual) charts, user-defined
  shape creation UI, offline PWA logging, Fly.io deploy
