require "rails_helper"

RSpec.describe Progression::Calculator do
  describe ".for" do
    it "returns an IntervalWorkCalculator for an interval_work session" do
      session = create(:session)

      expect(described_class.for(session)).to be_a(Progression::IntervalWorkCalculator)
    end

    it "raises for a session shape with no registered calculator" do
      session = create(:session, :fixed_reps_for_time)

      expect { described_class.for(session) }.to raise_error(Progression::Calculator::UnknownShapeError)
    end
  end
end
