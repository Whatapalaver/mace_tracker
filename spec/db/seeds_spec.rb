require "rails_helper"

RSpec.describe "db/seeds.rb" do
  def load_seeds
    load Rails.root.join("db/seeds.rb")
  end

  it "creates the three global session shapes" do
    load_seeds

    expect(SessionShape.where(user_id: nil).pluck(:name)).to contain_exactly(
      "interval_work", "fixed_reps_for_time", "emom"
    )
  end

  it "is idempotent when run more than once" do
    load_seeds
    expect { load_seeds }.not_to change(SessionShape, :count)
  end
end
