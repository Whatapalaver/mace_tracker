require "rails_helper"

RSpec.describe Progression::IntervalFormula do
  describe ".parse" do
    it "parses a flat N(work+rest) formula with a session-level weight suffix" do
      result = described_class.parse("5(5mw+5mr)@10kg")

      expect(result.weight_kg).to eq(10.0)
      expect(result.work_seconds).to eq(300)
      expect(result.rest_seconds).to eq(300)
      expect(result.sets_count).to eq(5)
      expect(result.work_segments.size).to eq(5)
    end

    it "parses a single unwrapped work segment with no rest" do
      result = described_class.parse("5mw@10kg")

      expect(result.weight_kg).to eq(10.0)
      expect(result.work_seconds).to eq(300)
      expect(result.rest_seconds).to eq(0)
      expect(result.sets_count).to eq(1)
    end

    it "accepts a decimal weight" do
      result = described_class.parse("3(30w+15r)@8.5kg")

      expect(result.weight_kg).to eq(8.5)
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
      session = build(:session, weight_kg: 10, work_seconds: 300, rest_seconds: 300, sets_count: 5)

      expect(described_class.render(session)).to eq("5(5mw+5mr)@10kg")
    end

    it "omits the N(...) wrapper for a single set" do
      session = build(:session, weight_kg: 10, work_seconds: 300, rest_seconds: 0, sets_count: 1)

      expect(described_class.render(session)).to eq("5mw@10kg")
    end

    it "omits the rest part when rest is zero" do
      session = build(:session, weight_kg: 10, work_seconds: 300, rest_seconds: 0, sets_count: 3)

      expect(described_class.render(session)).to eq("3(5mw)@10kg")
    end

    it "renders non-round-minute durations as bare seconds" do
      session = build(:session, weight_kg: 10, work_seconds: 45, rest_seconds: 20, sets_count: 5)

      expect(described_class.render(session)).to eq("5(45w+20r)@10kg")
    end

    it "renders a whole-number weight without a trailing decimal" do
      session = build(:session, weight_kg: 10.0, work_seconds: 300, rest_seconds: 0, sets_count: 1)

      expect(described_class.render(session)).to eq("5mw@10kg")
    end
  end

  describe ".render_without_weight" do
    it "renders the same body as .render, minus the weight suffix" do
      session = build(:session, weight_kg: 10, work_seconds: 300, rest_seconds: 300, sets_count: 5)

      expect(described_class.render_without_weight(session)).to eq("5(5mw+5mr)")
    end
  end

  describe "round-trip" do
    it "renders and re-parses to the same values" do
      session = build(:session, weight_kg: 8.5, work_seconds: 45, rest_seconds: 20, sets_count: 4)

      result = described_class.parse(described_class.render(session))

      expect(result.weight_kg).to eq(8.5)
      expect(result.work_seconds).to eq(45)
      expect(result.rest_seconds).to eq(20)
      expect(result.sets_count).to eq(4)
    end
  end
end
