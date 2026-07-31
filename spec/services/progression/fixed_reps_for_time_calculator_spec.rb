require "rails_helper"

RSpec.describe Progression::FixedRepsForTimeCalculator do
  subject(:calculator) { described_class.new(session) }

  let(:session) { create(:session, :fixed_reps_for_time, weight_kg: 10, target_reps: 100) }

  describe ".output_labels" do
    it "lists every output key" do
      expect(described_class.output_labels).to eq([ "Best time", "Avg time", "Best pace", "Avg pace" ])
    end
  end

  context "with a single attempt logged" do
    before do
      create(:session_set, session: session, set_number: 1, reps: 100, duration_seconds: 240)
    end

    it "reports best/avg time as that attempt's duration" do
      expect(calculator.best_time).to eq(240)
      expect(calculator.avg_time).to eq(240)
    end

    it "computes best/avg pace as reps per minute (reps / duration * 60)" do
      expect(calculator.best_pace).to eq(100 * 60.0 / 240)
      expect(calculator.avg_pace).to eq(100 * 60.0 / 240)
    end
  end

  context "with multiple independent timed attempts" do
    before do
      create(:session_set, session: session, set_number: 1, reps: 100, duration_seconds: 240)
      create(:session_set, session: session, set_number: 2, reps: 100, duration_seconds: 220)
      create(:session_set, session: session, set_number: 3, reps: 100, duration_seconds: 260)
    end

    it "computes best_time as the fastest (minimum) attempt" do
      expect(calculator.best_time).to eq(220)
    end

    it "computes avg_time as the mean across attempts" do
      expect(calculator.avg_time).to eq((240 + 220 + 260) / 3.0)
    end

    it "computes best_pace as the max reps/duration across attempts" do
      expect(calculator.best_pace).to eq(100 * 60.0 / 220)
    end

    it "computes avg_pace as the mean of per-attempt paces" do
      expect(calculator.avg_pace).to eq((100 * 60.0 / 240 + 100 * 60.0 / 220 + 100 * 60.0 / 260) / 3)
    end
  end

  context "when an attempt has no duration recorded" do
    before do
      create(:session_set, session: session, set_number: 1, reps: 100, duration_seconds: 240)
      create(:session_set, session: session, set_number: 2, reps: 100, duration_seconds: nil)
    end

    it "excludes it from times and pace_per_set" do
      expect(calculator.times).to eq([ 240 ])
      expect(calculator.pace_per_set.size).to eq(1)
    end
  end

  context "when nothing has been logged yet" do
    it "returns nil for every metric" do
      expect(calculator.best_time).to be_nil
      expect(calculator.avg_time).to be_nil
      expect(calculator.best_pace).to be_nil
      expect(calculator.avg_pace).to be_nil
    end
  end

  describe "#outputs" do
    it "returns raw values" do
      create(:session_set, session: session, set_number: 1, reps: 100, duration_seconds: 240)

      expect(calculator.outputs).to eq(
        "Best time" => 240, "Avg time" => 240.0, "Best pace" => 100 * 60.0 / 240, "Avg pace" => 100 * 60.0 / 240
      )
    end
  end

  describe "#display_outputs" do
    it "formats time with no decimals and shows an em dash when unavailable" do
      expect(calculator.display_outputs).to eq(
        "Best time" => "—", "Avg time" => "—", "Best pace" => "—", "Avg pace" => "—"
      )
    end

    it "rounds pace to 1 decimal with reps/min and time to whole seconds" do
      create(:session_set, session: session, set_number: 1, reps: 100, duration_seconds: 240)

      outputs = calculator.display_outputs

      expect(outputs["Best time"]).to eq(240)
      expect(outputs["Best pace"]).to eq("#{(100 * 60.0 / 240).round(1)} reps/min")
    end
  end
end
