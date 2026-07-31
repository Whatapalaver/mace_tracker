require "rails_helper"

RSpec.describe Progression::IntervalFormula do
  describe ".parse" do
    it "parses a flat N(work+rest) formula with a session-level weight suffix" do
      result = described_class.parse("5(5mw+5mr)@10kg")

      expect(result.planned_weight_kg).to eq(10.0)
      expect(result.planned_work_seconds).to eq(300)
      expect(result.planned_rest_seconds).to eq(300)
      expect(result.planned_sets).to eq(5)
      expect(result.work_segments.size).to eq(5)
    end

    it "parses a single unwrapped work segment with no rest" do
      result = described_class.parse("5mw@10kg")

      expect(result.planned_weight_kg).to eq(10.0)
      expect(result.planned_work_seconds).to eq(300)
      expect(result.planned_rest_seconds).to eq(0)
      expect(result.planned_sets).to eq(1)
    end

    it "accepts a decimal weight" do
      result = described_class.parse("3(30w+15r)@8.5kg")

      expect(result.planned_weight_kg).to eq(8.5)
    end

    it "raises when the weight suffix is missing" do
      expect { described_class.parse("5(5mw+5mr)") }.to raise_error(Progression::IntervalFormula::ParseError, /weight/i)
    end

    it "raises for invalid interval syntax, wrapping the underlying parser error" do
      expect { described_class.parse("5x@10kg") }.to raise_error(Progression::IntervalFormula::ParseError)
    end

    it "raises when the formula has no work segment" do
      expect { described_class.parse("30r@10kg") }.to raise_error(Progression::IntervalFormula::ParseError, /work segment/i)
    end
  end

  describe ".render" do
    it "renders a multi-set session with rest as N(Xmw+Ymr)@Wkg" do
      session = build(:session, planned_weight_kg: 10, planned_work_seconds: 300,
                                         planned_rest_seconds: 300, planned_sets: 5)

      expect(described_class.render(session)).to eq("5(5mw+5mr)@10kg")
    end

    it "omits the N(...) wrapper for a single set" do
      session = build(:session, planned_weight_kg: 10, planned_work_seconds: 300,
                                         planned_rest_seconds: 0, planned_sets: 1)

      expect(described_class.render(session)).to eq("5mw@10kg")
    end

    it "omits the rest part when rest is zero" do
      session = build(:session, planned_weight_kg: 10, planned_work_seconds: 300,
                                         planned_rest_seconds: 0, planned_sets: 3)

      expect(described_class.render(session)).to eq("3(5mw)@10kg")
    end

    it "renders non-round-minute durations as bare seconds" do
      session = build(:session, planned_weight_kg: 10, planned_work_seconds: 45,
                                         planned_rest_seconds: 20, planned_sets: 5)

      expect(described_class.render(session)).to eq("5(45w+20r)@10kg")
    end

    it "renders a whole-number weight without a trailing decimal" do
      session = build(:session, planned_weight_kg: 10.0, planned_work_seconds: 300,
                                         planned_rest_seconds: 0, planned_sets: 1)

      expect(described_class.render(session)).to eq("5mw@10kg")
    end
  end

  describe "round-trip" do
    it "renders and re-parses to the same planned values" do
      session = build(:session, planned_weight_kg: 8.5, planned_work_seconds: 45,
                                         planned_rest_seconds: 20, planned_sets: 4)

      result = described_class.parse(described_class.render(session))

      expect(result.planned_weight_kg).to eq(8.5)
      expect(result.planned_work_seconds).to eq(45)
      expect(result.planned_rest_seconds).to eq(20)
      expect(result.planned_sets).to eq(4)
    end
  end
end
