namespace :historic do
  desc "One-time bulk import of real historic sessions logged before this app existed"
  task import: [ :environment, "db:seed" ] do
    exercises = {
      "double" => Exercise.find_by!(name: "Mace 10-2", arm: "double", user_id: nil),
      "single" => Exercise.find_by!(name: "Mace 10-2", arm: "single", user_id: nil)
    }
    shape = SessionShape.find_by!(name: SessionShape::INTERVAL_WORK, user_id: nil)

    # Each row is one interval_work session: weight_kg/work_seconds/rest_seconds/sets_count
    # describe the notation it was logged as (e.g. "5mw@10kg" -> work 300, rest 0, 1 set;
    # "3(5mw+2mr)@10kg" -> work 300, rest 120, 3 sets), :reps has one entry per set in order.
    # Safe to keep appending rows and re-running: for each distinct row, only the shortfall
    # between how many times it appears here and how many matching sessions already exist gets
    # created (see the group_by below) — genuine same-day/same-signature repeats (see 2026-07-27
    # and 2026-06-09) are counted correctly since duplicate rows just raise the expected count.
    rows = [
      { arm: "double", date: Date.new(2026, 1, 7), weight_kg: 10, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 197 ], is_benchmark: true },
      { arm: "double", date: Date.new(2026, 1, 7), weight_kg: 10, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 167 ], is_benchmark: false },
      { arm: "double", date: Date.new(2026, 1, 11), weight_kg: 10, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 197 ], is_benchmark: true },
      { arm: "single", date: Date.new(2026, 1, 31), weight_kg: 8, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 177 ], is_benchmark: false },
      { arm: "single", date: Date.new(2026, 1, 31), weight_kg: 7.5, work_seconds: 1800, rest_seconds: 0,
        sets_count: 1, reps: [ 177 ], is_benchmark: false },
      { arm: "double", date: Date.new(2026, 1, 30), weight_kg: 10, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 199 ], is_benchmark: true },
      { arm: "single", date: Date.new(2026, 3, 23), weight_kg: 10, work_seconds: 300, rest_seconds: 300,
        sets_count: 3, reps: [ 184, 181, 175 ], is_benchmark: false },
      { arm: "double", date: Date.new(2026, 5, 5), weight_kg: 10, work_seconds: 300, rest_seconds: 120,
        sets_count: 3, reps: [ 200, 195, 179 ], is_benchmark: false },
      { arm: "double", date: Date.new(2026, 5, 18), weight_kg: 10, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 202 ], is_benchmark: true },
      { arm: "double", date: Date.new(2026, 5, 18), weight_kg: 8, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 208 ], is_benchmark: false },
      { arm: "double", date: Date.new(2026, 5, 25), weight_kg: 12, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 193 ], is_benchmark: false },
      { arm: "double", date: Date.new(2026, 6, 9), weight_kg: 10, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 209 ], is_benchmark: true },
      { arm: "double", date: Date.new(2026, 6, 9), weight_kg: 10, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 214 ], is_benchmark: true },
      { arm: "double", date: Date.new(2026, 6, 9), weight_kg: 12, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 202 ], is_benchmark: false },
      { arm: "double", date: Date.new(2026, 6, 9), weight_kg: 12, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 155 ], is_benchmark: false },
      { arm: "double", date: Date.new(2026, 7, 27), weight_kg: 10, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 227 ], is_benchmark: true },
      { arm: "double", date: Date.new(2026, 7, 27), weight_kg: 10, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 230 ], is_benchmark: true },
      { arm: "double", date: Date.new(2026, 7, 27), weight_kg: 10, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 229 ], is_benchmark: true },
      { arm: "double", date: Date.new(2026, 7, 27), weight_kg: 10, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 228 ], is_benchmark: true },
      { arm: "double", date: Date.new(2026, 7, 27), weight_kg: 10, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 229 ], is_benchmark: true },
      { arm: "double", date: Date.new(2026, 7, 27), weight_kg: 10, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 207 ], is_benchmark: true },
      { arm: "double", date: Date.new(2026, 7, 27), weight_kg: 10, work_seconds: 300, rest_seconds: 0,
        sets_count: 1, reps: [ 217 ], is_benchmark: true }
    ]

    created = 0
    rows.group_by(&:itself).each do |row, occurrences|
      exercise = exercises.fetch(row[:arm])
      existing = Session.where(date: row[:date], exercise: exercise, session_shape: shape,
                                weight_kg: row[:weight_kg], work_seconds: row[:work_seconds],
                                rest_seconds: row[:rest_seconds], sets_count: row[:sets_count],
                                is_benchmark: row[:is_benchmark])
                         .count { |session| session.session_sets.order(:set_number).pluck(:reps) == row[:reps] }

      (occurrences.size - existing).times do
        session = Session.create!(date: row[:date], exercise: exercise, session_shape: shape,
                                   weight_kg: row[:weight_kg], work_seconds: row[:work_seconds],
                                   rest_seconds: row[:rest_seconds], sets_count: row[:sets_count],
                                   is_benchmark: row[:is_benchmark])
        row[:reps].each_with_index { |reps, index| session.session_sets.create!(set_number: index + 1, reps: reps) }
        created += 1
      end
    end

    puts "Imported #{created} new historic sessions (#{rows.size - created} already present)."
  end
end
