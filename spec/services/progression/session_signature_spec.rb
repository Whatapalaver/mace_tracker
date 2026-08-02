require "rails_helper"

RSpec.describe Progression::SessionSignature do
  describe ".parse" do
    it "parses interval_work notation into work_seconds, rest_seconds, and sets_count" do
      result = described_class.parse("3(5mw+5mr)", SessionShape::INTERVAL_WORK)

      expect(result).to eq(work_seconds: 300, rest_seconds: 300, sets_count: 3)
    end

    it "parses a single unwrapped interval_work segment with no rest" do
      result = described_class.parse("5mw", SessionShape::INTERVAL_WORK)

      expect(result).to eq(work_seconds: 300, rest_seconds: 0, sets_count: 1)
    end

    it "raises for invalid interval_work notation" do
      expect { described_class.parse("not a formula", SessionShape::INTERVAL_WORK) }
        .to raise_error(Progression::SessionSignature::ParseError)
    end

    it "parses a bare number for fixed_reps_for_time" do
      expect(described_class.parse("108", SessionShape::FIXED_REPS_FOR_TIME)).to eq(reps: 108)
    end

    it "parses a bare number for emom" do
      expect(described_class.parse("20", SessionShape::EMOM)).to eq(reps_per_minute: 20)
    end

    it "raises when fixed_reps_for_time/emom signature isn't a whole number" do
      expect { described_class.parse("abc", SessionShape::FIXED_REPS_FOR_TIME) }
        .to raise_error(Progression::SessionSignature::ParseError)
    end
  end
end
