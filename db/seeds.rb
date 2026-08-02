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
  },
  {
    name: "sets_and_reps",
    description: "Untimed straight sets, e.g. 4 sets of 24 reps"
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
    reps: 108
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
    preset.reps = attrs[:reps]
  end
end
