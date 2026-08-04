require "csv"

namespace :hevy do
  desc "One-time bulk import of historic Mace/Kettlebell sessions exported from the Hevy app"
  task import: :environment do
    shape = SessionShape.find_by!(name: SessionShape::SETS_AND_REPS, user_id: nil)

    # Maps Hevy's own exercise_title strings to this app's (equipment, name, arm) records —
    # derived from inspecting every distinct exercise_title in the export. "Kettlebell Snatch"
    # has no double-arm variant anywhere in the export (weights are consistently single-bell
    # scale), and "KB Long Cycle" (no "Single Arm" suffix) is confirmed double-arm by an explicit
    # "2x8kg" note on one entry.
    exercise_map = {
      "Mace Swing - 360" => { equipment: "Mace", name: "360", arm: "double" },
      "Mace 360 1H" => { equipment: "Mace", name: "360", arm: "single" },
      "Mace 10-2" => { equipment: "Mace", name: "10-2", arm: "double" },
      "Mace 10-2 1H" => { equipment: "Mace", name: "10-2", arm: "single" },
      "Kettlebell Snatch" => { equipment: "Kettlebell", name: "Snatch", arm: "single" },
      "KB Long Cycle" => { equipment: "Kettlebell", name: "Long Cycle", arm: "double" },
      "KB Long Cycle Single Arm" => { equipment: "Kettlebell", name: "Long Cycle", arm: "single" }
    }

    exercises = exercise_map.transform_values do |attrs|
      equipment = Equipment.find_by!(name: attrs[:equipment], user_id: nil)
      Exercise.find_by!(name: attrs[:name], arm: attrs[:arm], equipment: equipment, user_id: nil)
    end

    rows = CSV.read(Rails.root.join("lib/tasks/data/hevy_mace.csv"), headers: true)
    groups = rows.group_by { |row| [ row["title"], row["start_time"], row["exercise_title"] ] }

    created_sessions = 0
    created_sets = 0
    skipped_existing = 0
    skipped_unmapped = 0

    groups.each_value do |group_rows|
      exercise = exercises[group_rows.first["exercise_title"]]
      unless exercise
        skipped_unmapped += 1
        next
      end

      date = Date.strptime(group_rows.first["date"], "%d/%m/%Y")

      if Session.exists?(date: date, exercise: exercise)
        skipped_existing += 1
        next
      end

      # The Hevy export re-numbers set_index within some ad-hoc ladder/complex workouts, so two
      # rows can share a set_index while being genuinely distinct sets (different weight/reps) —
      # only rows that are exact duplicates across index/weight/reps are the same literal export
      # glitch and should collapse to one set.
      set_rows = group_rows.uniq { |row| [ row["set_index"], row["weight_kg"], row["reps"] ] }

      session = Session.create!(
        date: date,
        exercise: exercise,
        session_shape: shape,
        weight_kg: set_rows.first["weight_kg"].presence,
        reps: set_rows.first["reps"].presence
      )

      set_rows.each_with_index do |row, index|
        session.session_sets.create!(
          set_number: index + 1,
          weight_kg: row["weight_kg"].presence,
          reps: row["reps"].presence
        )
      end

      created_sessions += 1
      created_sets += set_rows.size
    end

    puts "Created #{created_sessions} sessions (#{created_sets} sets)."
    puts "Skipped #{skipped_existing} sessions — already present for that date/exercise."
    puts "Skipped #{skipped_unmapped} groups with an unmapped exercise_title." if skipped_unmapped.positive?
  end
end
