require "rails_helper"

RSpec.describe Progression::SessionFormula do
  describe ".parse" do
    it "dispatches interval_work to IntervalFormula" do
      result = described_class.parse("5(5mw+5mr)@10kg", SessionShape::INTERVAL_WORK)

      expect(result).to be_a(Progression::IntervalFormula::Result)
      expect(result.sets_count).to eq(5)
    end

    it "dispatches fixed_reps_for_time to RepsFormula" do
      result = described_class.parse("5(108@10kg)", SessionShape::FIXED_REPS_FOR_TIME)

      expect(result).to be_a(Progression::RepsFormula::Result)
      expect(result.reps).to eq(108)
    end

    it "dispatches emom to RepsFormula" do
      result = described_class.parse("10(20@10kg)", SessionShape::EMOM)

      expect(result).to be_a(Progression::RepsFormula::Result)
      expect(result.count).to eq(10)
    end

    it "raises a uniform ParseError for interval_work syntax errors" do
      expect {
        described_class.parse("5(5mw+5mr)", SessionShape::INTERVAL_WORK)
      }.to raise_error(Progression::SessionFormula::ParseError)
    end

    it "raises a uniform ParseError for reps-dialect syntax errors" do
      expect {
        described_class.parse("not a formula", SessionShape::EMOM)
      }.to raise_error(Progression::SessionFormula::ParseError)
    end

    it "raises for an unregistered shape" do
      expect {
        described_class.parse("anything", "unregistered_shape")
      }.to raise_error(Progression::SessionFormula::ParseError)
    end
  end
end
