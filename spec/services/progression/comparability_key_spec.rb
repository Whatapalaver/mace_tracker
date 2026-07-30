require "rails_helper"

RSpec.describe Progression::ComparabilityKey do
  describe ".for" do
    it "builds a key from exercise, shape, weight, and work duration for interval_work" do
      session = create(:session, planned_weight_kg: 10, planned_work_seconds: 300)

      expect(described_class.for(session)).to eq(
        exercise_id: session.exercise_id,
        session_shape_id: session.session_shape_id,
        weight: 10.0,
        work_duration: 300
      )
    end

    it "raises for a shape with no defined comparability key" do
      session = create(:session, :fixed_reps_for_time)

      expect { described_class.for(session) }.to raise_error(Progression::ComparabilityKey::UnknownShapeError)
    end
  end
end
