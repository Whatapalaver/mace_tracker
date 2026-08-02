namespace :historic do
  desc "One-time bulk import of real historic sessions logged before this app existed"
  task import: [ :environment, "db:seed" ] do
    exercise = Exercise.find_by!(name: "Mace 10-2", arm: "double", user_id: nil)
    shape = SessionShape.find_by!(name: SessionShape::INTERVAL_WORK, user_id: nil)

    # All "5mw@10kg" — a single unwrapped 5-minute work segment, no rest: weight_kg 10,
    # work_seconds 300, rest_seconds 0, sets_count 1. Real logs can repeat the same date and
    # even the same rep count (see 2026-07-27), so unlike the rest of this app's seed data this
    # is NOT find_or_create_by!-idempotent — it's a run-once backfill, guarded below against
    # accidental double-invocation rather than per-row content matching.
    rows = [
      { date: Date.new(2026, 1, 7), reps: 197, is_benchmark: true },
      { date: Date.new(2026, 1, 7), reps: 167, is_benchmark: false },
      { date: Date.new(2026, 1, 11), reps: 197, is_benchmark: true },
      { date: Date.new(2026, 1, 30), reps: 199, is_benchmark: true },
      { date: Date.new(2026, 5, 18), reps: 202, is_benchmark: true },
      { date: Date.new(2026, 6, 9), reps: 209, is_benchmark: true },
      { date: Date.new(2026, 6, 9), reps: 214, is_benchmark: true },
      { date: Date.new(2026, 7, 27), reps: 227, is_benchmark: true },
      { date: Date.new(2026, 7, 27), reps: 230, is_benchmark: true },
      { date: Date.new(2026, 7, 27), reps: 229, is_benchmark: true },
      { date: Date.new(2026, 7, 27), reps: 228, is_benchmark: true },
      { date: Date.new(2026, 7, 27), reps: 229, is_benchmark: true },
      { date: Date.new(2026, 7, 27), reps: 207, is_benchmark: true },
      { date: Date.new(2026, 7, 27), reps: 217, is_benchmark: true }
    ]

    existing = Session.where(exercise: exercise, session_shape: shape, weight_kg: 10,
                              work_seconds: 300, rest_seconds: 0, sets_count: 1).count
    if existing >= rows.size
      abort "Found #{existing} matching sessions already — looks like this import already ran. " \
            "Delete them first if you need to re-run."
    end

    rows.each do |row|
      session = Session.create!(date: row[:date], exercise: exercise, session_shape: shape,
                                 weight_kg: 10, work_seconds: 300, rest_seconds: 0, sets_count: 1,
                                 is_benchmark: row[:is_benchmark])
      session.session_sets.create!(set_number: 1, reps: row[:reps])
    end

    puts "Imported #{rows.size} historic sessions."
  end
end
