require "rails_helper"

# Ported unchanged from warrior_timer's spec/services/intervals/expander_spec.rb — the Expander
# only reads segment[:type]/[:duration] opaquely, so it's untouched by restricting Parser's
# segment types to work/rest. Kept the warmup/prepare/cooldown hand-built fixtures here since
# they exercise the Expander's own logic (round numbers around non-repeating segments), not the
# Parser's grammar.
RSpec.describe Progression::IntervalNotation::Expander do
  describe "#expand" do
    it "expands simple segments with metadata" do
      parsed = [
        { type: :work, duration: 30 },
        { type: :rest, duration: 15 }
      ]

      result = described_class.new(parsed).expand

      expect(result.length).to eq(2)
      expect(result[0]).to include(
        segment_type: :work,
        duration_seconds: 30,
        segment_index: 0,
        total_segments: 2
      )
      expect(result[1]).to include(
        segment_type: :rest,
        duration_seconds: 15,
        segment_index: 1,
        total_segments: 2
      )
    end

    it "calculates round numbers for repetitions" do
      parsed = []
      3.times do
        parsed << { type: :work, duration: 30, repetition: true }
        parsed << { type: :rest, duration: 15, repetition: true }
      end

      result = described_class.new(parsed).expand

      expect(result.length).to eq(6)
      expect(result[0][:round_number]).to eq(1)
      expect(result[1][:round_number]).to eq(1)
      expect(result[2][:round_number]).to eq(2)
      expect(result[3][:round_number]).to eq(2)
      expect(result[4][:round_number]).to eq(3)
      expect(result[5][:round_number]).to eq(3)

      expect(result[0][:total_rounds]).to eq(3)
      expect(result[5][:total_rounds]).to eq(3)
    end

    it "handles mixed repetitions and non-repetitions" do
      parsed = [
        { type: :prepare, duration: 10 },
        { type: :work, duration: 30, repetition: true },
        { type: :rest, duration: 15, repetition: true },
        { type: :work, duration: 30, repetition: true },
        { type: :rest, duration: 15, repetition: true },
        { type: :cooldown, duration: 60 }
      ]

      result = described_class.new(parsed).expand

      expect(result.length).to eq(6)
      expect(result[0][:round_number]).to be_nil
      expect(result[1][:round_number]).to eq(1)
      expect(result[2][:round_number]).to eq(1)
      expect(result[3][:round_number]).to eq(2)
      expect(result[4][:round_number]).to eq(2)
      expect(result[5][:round_number]).to be_nil
    end

    it "calculates total duration" do
      parsed = [
        { type: :prepare, duration: 10 },
        { type: :work, duration: 60, repetition: true },
        { type: :rest, duration: 30, repetition: true },
        { type: :work, duration: 60, repetition: true },
        { type: :rest, duration: 30, repetition: true }
      ]

      expander = described_class.new(parsed)
      expander.expand

      expect(expander.total_duration).to eq(190) # 10 + 60 + 30 + 60 + 30
    end

    it "includes segment type string" do
      parsed = [
        { type: :work, duration: 30 },
        { type: :rest, duration: 15 }
      ]

      result = described_class.new(parsed).expand

      expect(result[0][:segment_type]).to eq(:work)
      expect(result[1][:segment_type]).to eq(:rest)
    end

    it "handles complex workout structure" do
      # 10p+5mwu+8(3mw1mr)+2mcd
      parsed = [
        { type: :prepare, duration: 10 },
        { type: :warmup, duration: 300 }
      ]
      8.times do
        parsed << { type: :work, duration: 180, repetition: true }
        parsed << { type: :rest, duration: 60, repetition: true }
      end
      parsed << { type: :cooldown, duration: 120 }

      result = described_class.new(parsed).expand

      expect(result.length).to eq(19) # 2 + 16 + 1
      expect(result[0][:round_number]).to be_nil
      expect(result[1][:round_number]).to be_nil
      expect(result[2][:round_number]).to eq(1)
      expect(result[3][:round_number]).to eq(1)
      expect(result[4][:round_number]).to eq(2)
      expect(result[-2][:round_number]).to eq(8)
      expect(result[-1][:round_number]).to be_nil
    end
  end
end
