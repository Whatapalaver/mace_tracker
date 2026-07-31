# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

[
  {
    name: "interval_work",
    description: "Work/rest interval sets, e.g. 5 min work, 10 min rest, 5 sets"
  },
  {
    name: "fixed_reps_for_time",
    description: "A fixed number of reps performed as fast as possible, timed"
  },
  {
    name: "emom",
    description: "A fixed number of reps every minute on the minute, until failure"
  }
].each do |attrs|
  SessionShape.find_or_create_by!(name: attrs[:name], user_id: nil) do |shape|
    shape.description = attrs[:description]
  end
end

[
  { name: "Mace 360", arm: "single" },
  { name: "Mace 360", arm: "double" },
  { name: "Mace 10-2", arm: "single" },
  { name: "Mace 10-2", arm: "double" }
].each do |attrs|
  Exercise.find_or_create_by!(name: attrs[:name], arm: attrs[:arm], user_id: nil)
end

mace_10_2_double = Exercise.find_by!(name: "Mace 10-2", arm: "double", user_id: nil)
interval_work = SessionShape.find_by!(name: SessionShape::INTERVAL_WORK, user_id: nil)
fixed_reps_for_time = SessionShape.find_by!(name: SessionShape::FIXED_REPS_FOR_TIME, user_id: nil)

[
  {
    name: "Time to 108",
    exercise: mace_10_2_double,
    session_shape: fixed_reps_for_time,
    weight_kg: 8,
    target_reps: 108
  },
  {
    name: "5 x 5",
    exercise: mace_10_2_double,
    session_shape: interval_work,
    weight_kg: 10,
    work_seconds: 300,
    rest_seconds: 300,
    sets_count: 5
  },
  {
    name: "5min sprint",
    exercise: mace_10_2_double,
    session_shape: interval_work,
    weight_kg: 10,
    work_seconds: 300,
    rest_seconds: 0,
    sets_count: 1
  }
].each do |attrs|
  BenchmarkPreset.find_or_create_by!(name: attrs[:name]) do |preset|
    preset.exercise = attrs[:exercise]
    preset.session_shape = attrs[:session_shape]
    preset.weight_kg = attrs[:weight_kg]
    preset.work_seconds = attrs[:work_seconds]
    preset.rest_seconds = attrs[:rest_seconds]
    preset.sets_count = attrs[:sets_count]
    preset.target_reps = attrs[:target_reps]
  end
end

# Historic sessions — fill in with real logged data below. One example per shape is included
# to show the field names each one needs; :sets is the actual reps (and, for interval_work,
# optional per-set duration_seconds/weight_kg/rest_seconds_actual overrides) recorded for each
# set. find_or_create_by! is keyed on date+exercise+shape so this file stays safe to re-run.
emom = SessionShape.find_by!(name: SessionShape::EMOM, user_id: nil)

[
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
    target_reps: 108,
    sets: [ { reps: 108, duration_seconds: 240 } ]
  },
  {
    date: Date.new(2026, 1, 19),
    exercise: mace_10_2_double,
    session_shape: emom,
    weight_kg: 10,
    target_reps_per_minute: 20,
    sets: [ { reps: 20 }, { reps: 20 }, { reps: 20 }, { reps: 20 }, { reps: 20 }, { reps: 20 }, { reps: 20 }, { reps: 20 },
            { reps: 20 }, { reps: 20 } ]
  }
].each do |attrs|
  session = Session.find_or_create_by!(date: attrs[:date], exercise: attrs[:exercise],
                                        session_shape: attrs[:session_shape]) do |s|
    s.weight_kg = attrs[:weight_kg]
    s.work_seconds = attrs[:work_seconds]
    s.rest_seconds = attrs[:rest_seconds]
    s.sets_count = attrs[:sets_count]
    s.target_reps = attrs[:target_reps]
    s.target_reps_per_minute = attrs[:target_reps_per_minute]
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
