require "rails_helper"

RSpec.describe Progression::RepsFormula do
  describe ".parse" do
    it "parses count, reps, and weight from N(X@Wkg)" do
      result = described_class.parse("5(108@10kg)")

      expect(result.count).to eq(5)
      expect(result.reps).to eq(108)
      expect(result.weight_kg).to eq(10.0)
    end

    it "parses the emom example" do
      result = described_class.parse("10(20@10kg)")

      expect(result.count).to eq(10)
      expect(result.reps).to eq(20)
      expect(result.weight_kg).to eq(10.0)
    end

    it "accepts a decimal weight" do
      result = described_class.parse("5(108@8.5kg)")

      expect(result.weight_kg).to eq(8.5)
    end

    it "raises for malformed input" do
      expect { described_class.parse("108@10kg") }.to raise_error(Progression::RepsFormula::ParseError)
    end

    it "raises for a zero count" do
      expect { described_class.parse("0(108@10kg)") }.to raise_error(Progression::RepsFormula::ParseError)
    end

    it "raises for zero reps" do
      expect { described_class.parse("5(0@10kg)") }.to raise_error(Progression::RepsFormula::ParseError)
    end
  end

  describe ".render" do
    it "renders count, reps, and weight as N(X@Wkg)" do
      expect(described_class.render(count: 5, reps: 108, weight_kg: 10)).to eq("5(108@10kg)")
    end

    it "renders a whole-number weight without a trailing decimal" do
      expect(described_class.render(count: 10, reps: 20, weight_kg: 10.0)).to eq("10(20@10kg)")
    end

    it "renders a decimal weight" do
      expect(described_class.render(count: 5, reps: 108, weight_kg: 8.5)).to eq("5(108@8.5kg)")
    end
  end

  describe "round-trip" do
    it "renders and re-parses to the same values" do
      rendered = described_class.render(count: 5, reps: 108, weight_kg: 8.5)
      result = described_class.parse(rendered)

      expect(result.count).to eq(5)
      expect(result.reps).to eq(108)
      expect(result.weight_kg).to eq(8.5)
    end
  end
end
