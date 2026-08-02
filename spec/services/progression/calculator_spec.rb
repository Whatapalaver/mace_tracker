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

    it "returns a SetsAndRepsCalculator for a sets_and_reps session" do
      session = create(:session, :sets_and_reps)

      expect(described_class.for(session)).to be_a(Progression::SetsAndRepsCalculator)
    end

    it "raises for a session shape with no registered calculator" do
      shape = create(:session_shape, name: "unregistered_shape")
      session = create(:session, session_shape: shape)

      expect { described_class.for(session) }.to raise_error(Progression::Calculator::UnknownShapeError)
    end
  end

  describe ".output_labels_for" do
    it "delegates to the registered calculator's output_labels" do
      expect(described_class.output_labels_for(SessionShape::EMOM)).to eq([ "Sets completed" ])
    end

    it "raises for an unregistered shape" do
      expect { described_class.output_labels_for("unregistered_shape") }.to raise_error(
        Progression::Calculator::UnknownShapeError
      )
    end
  end
end
