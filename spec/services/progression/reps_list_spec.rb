require "rails_helper"

RSpec.describe Progression::RepsList do
  describe ".parse" do
    it "parses a bare comma-separated list of reps with no weight" do
      entries = described_class.parse("200, 189, 199")

      expect(entries).to eq(
        [
          Progression::RepsList::Entry.new(reps: 200, weight_kg: nil),
          Progression::RepsList::Entry.new(reps: 189, weight_kg: nil),
          Progression::RepsList::Entry.new(reps: 199, weight_kg: nil)
        ]
      )
    end

    it "parses a per-set weight override with @weight" do
      entries = described_class.parse("100@6, 100@6, 50@8")

      expect(entries).to eq(
        [
          Progression::RepsList::Entry.new(reps: 100, weight_kg: 6.0),
          Progression::RepsList::Entry.new(reps: 100, weight_kg: 6.0),
          Progression::RepsList::Entry.new(reps: 50, weight_kg: 8.0)
        ]
      )
    end

    it "allows mixing bare and @weight entries in the same list" do
      entries = described_class.parse("200, 189@8, 199")

      expect(entries.map(&:weight_kg)).to eq([ nil, 8.0, nil ])
    end

    it "accepts a decimal weight" do
      entries = described_class.parse("100@7.5")

      expect(entries.first.weight_kg).to eq(7.5)
    end

    it "tolerates surrounding whitespace" do
      entries = described_class.parse(" 200 , 189 , 199 ")

      expect(entries.map(&:reps)).to eq([ 200, 189, 199 ])
    end

    it "raises when the list is empty" do
      expect { described_class.parse("") }.to raise_error(Progression::RepsList::ParseError, /at least one/i)
    end

    it "raises when the list is only whitespace/commas" do
      expect { described_class.parse(" , , ") }.to raise_error(Progression::RepsList::ParseError)
    end

    it "raises on a non-numeric entry" do
      expect { described_class.parse("200, abc") }.to raise_error(Progression::RepsList::ParseError)
    end

    it "raises on a malformed weight suffix" do
      expect { described_class.parse("200@") }.to raise_error(Progression::RepsList::ParseError)
    end

    describe "expected_count" do
      it "repeats a single entry to fill every set when a multi-set count is expected" do
        entries = described_class.parse("7", expected_count: 50)

        expect(entries.size).to eq(50)
        expect(entries.uniq).to eq([ Progression::RepsList::Entry.new(reps: 7, weight_kg: nil) ])
      end

      it "repeats a single weight-overridden entry too" do
        entries = described_class.parse("7@6", expected_count: 3)

        expect(entries).to eq(Array.new(3, Progression::RepsList::Entry.new(reps: 7, weight_kg: 6.0)))
      end

      it "does not expand a genuine multi-entry list, even if its length still disagrees" do
        entries = described_class.parse("7, 8", expected_count: 50)

        expect(entries.size).to eq(2)
      end

      it "does not expand a single entry when expected_count is 1" do
        entries = described_class.parse("7", expected_count: 1)

        expect(entries.size).to eq(1)
      end

      it "does not expand when expected_count is nil" do
        entries = described_class.parse("7")

        expect(entries.size).to eq(1)
      end
    end
  end
end
