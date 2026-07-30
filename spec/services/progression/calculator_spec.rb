require "rails_helper"

RSpec.describe Progression::Calculator do
  describe ".for" do
    it "returns an IntervalWorkCalculator for an interval_work session" do
      session = create(:session)

      expect(described_class.for(session)).to be_a(Progression::IntervalWorkCalculator)
    end

    it "returns a FixedRepsForTimeCalculator for a fixed_reps_for_time session" do
      session = create(:session, :fixed_reps_for_time)

      expect(described_class.for(session)).to be_a(Progression::FixedRepsForTimeCalculator)
    end

    it "returns an EmomCalculator for an emom session" do
      session = create(:session, :emom)

      expect(described_class.for(session)).to be_a(Progression::EmomCalculator)
    end

    it "raises for a session shape with no registered calculator" do
      shape = create(:session_shape, name: "unregistered_shape")
      session = create(:session, session_shape: shape)

      expect { described_class.for(session) }.to raise_error(Progression::Calculator::UnknownShapeError)
    end
  end
end
