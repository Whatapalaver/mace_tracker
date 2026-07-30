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
