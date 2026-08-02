namespace :historic do
  desc "Import real historic sessions — edit the SESSIONS array below with your own logged data first"
  task import: [ :environment, "db:seed" ] do
    mace_10_2_double = Exercise.find_by!(name: "Mace 10-2", arm: "double", user_id: nil)
    interval_work = SessionShape.find_by!(name: SessionShape::INTERVAL_WORK, user_id: nil)
    fixed_reps_for_time = SessionShape.find_by!(name: SessionShape::FIXED_REPS_FOR_TIME, user_id: nil)
    emom = SessionShape.find_by!(name: SessionShape::EMOM, user_id: nil)

    # One example per shape, showing the field names each one needs; :sets is the actual reps
    # (and, for interval_work, optional per-set duration_seconds/weight_kg/rest_seconds_actual
    # overrides) recorded for each set. For fixed_reps_for_time/emom, the session's own
    # :reps/:reps_per_minute duplicates what every set's :reps ends up being — both are set
    # because every set shares that one fixed count. Replace these with your real sessions;
    # find_or_create_by! is keyed on date+exercise+shape so re-running stays safe.
    sessions = [
      {
        date: Date.new(2026, 1, 5),
        exercise: mace_10_2_double,
        session_shape: interval_work,
        weight_kg: 10,
        work_seconds: 300,
        rest_seconds: 300,
        sets_count: 5,
        sets: [ { reps: 20 }, { reps: 19 }, { reps: 18 }, { reps: 18 }, { reps: 17 } ]
      },
      {
        date: Date.new(2026, 1, 12),
        exercise: mace_10_2_double,
        session_shape: fixed_reps_for_time,
        weight_kg: 8,
        reps: 108,
        sets: [ { reps: 108, duration_seconds: 240 } ]
      },
      {
        date: Date.new(2026, 1, 19),
        exercise: mace_10_2_double,
        session_shape: emom,
        weight_kg: 10,
        reps_per_minute: 20,
        sets: 10.times.map { { reps: 20 } }
      }
    ]

    sessions.each do |attrs|
      session = Session.find_or_create_by!(date: attrs[:date], exercise: attrs[:exercise],
                                            session_shape: attrs[:session_shape]) do |s|
        s.weight_kg = attrs[:weight_kg]
        s.work_seconds = attrs[:work_seconds]
        s.rest_seconds = attrs[:rest_seconds]
        s.sets_count = attrs[:sets_count]
        s.reps = attrs[:reps]
        s.reps_per_minute = attrs[:reps_per_minute]
        s.is_benchmark = attrs[:is_benchmark] || false
        s.notes = attrs[:notes]
      end

      attrs[:sets].each_with_index do |set_attrs, index|
        session.session_sets.find_or_create_by!(set_number: index + 1) do |set|
          set.reps = set_attrs[:reps]
          set.duration_seconds = set_attrs[:duration_seconds]
          set.weight_kg = set_attrs[:weight_kg]
          set.rest_seconds_actual = set_attrs[:rest_seconds_actual]
        end
      end
    end

    puts "Imported historic sessions: #{Session.count} sessions, #{SessionSet.count} sets total."
  end
end
