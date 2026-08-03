require "rails_helper"

RSpec.describe "db/seeds.rb" do
  def load_seeds
    load Rails.root.join("db/seeds.rb")
  end

  it "creates the four global session shapes" do
    load_seeds

    expect(SessionShape.where(user_id: nil).pluck(:name)).to contain_exactly(
      "interval_work", "fixed_reps_for_time", "emom", "sets_and_reps"
    )
  end

  it "creates the Mace equipment and its four global exercises" do
    load_seeds

    expect(Equipment.where(user_id: nil).pluck(:name)).to contain_exactly("Mace")

    exercises = Exercise.where(user_id: nil).pluck(:name, :arm)
    expect(exercises).to contain_exactly(
      [ "360", "single" ], [ "360", "double" ],
      [ "10-2", "single" ], [ "10-2", "double" ]
    )
  end

  it "creates the three benchmark presets against Mace 10-2 (double)" do
    load_seeds

    mace_10_2_double = Exercise.find_by!(name: "10-2", arm: "double", equipment: Equipment.find_by!(name: "Mace"),
                                          user_id: nil)
    presets = BenchmarkPreset.where(exercise: mace_10_2_double).index_by(&:name)

    expect(presets.keys).to contain_exactly("Time to 108", "5 x 5", "5min sprint")

    time_to_108 = presets.fetch("Time to 108")
    expect(time_to_108.session_shape.name).to eq(SessionShape::FIXED_REPS_FOR_TIME)
    expect(time_to_108.weight_kg).to eq(8)
    expect(time_to_108.reps).to eq(108)

    five_by_five = presets.fetch("5 x 5")
    expect(five_by_five.session_shape.name).to eq(SessionShape::INTERVAL_WORK)
    expect(five_by_five.weight_kg).to eq(10)
    expect(five_by_five.work_seconds).to eq(300)
    expect(five_by_five.rest_seconds).to eq(300)
    expect(five_by_five.sets_count).to eq(5)

    sprint = presets.fetch("5min sprint")
    expect(sprint.session_shape.name).to eq(SessionShape::INTERVAL_WORK)
    expect(sprint.work_seconds).to eq(300)
    expect(sprint.rest_seconds).to eq(0)
    expect(sprint.sets_count).to eq(1)
  end

  it "is idempotent when run more than once" do
    load_seeds

    expect { load_seeds }.not_to change(SessionShape, :count)
    expect { load_seeds }.not_to change(Equipment, :count)
    expect { load_seeds }.not_to change(Exercise, :count)
    expect { load_seeds }.not_to change(BenchmarkPreset, :count)
  end
end
