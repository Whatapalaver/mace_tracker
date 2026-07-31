require "rails_helper"

RSpec.describe Progression::IntervalWorkCalculator do
  subject(:calculator) { described_class.new(session) }

  describe ".output_labels" do
    it "lists every output key, matching #outputs" do
      expect(described_class.output_labels).to eq(
        [ "Best pace", "Avg pace", "Total output", "Output / total time", "Output / working time" ]
      )
    end
  end

  let(:session) do
    create(:session, planned_weight_kg: 10, planned_work_seconds: 300, planned_rest_seconds: 600, planned_sets: 5)
  end

  context "with sets relying on the session's planned durations" do
    before do
      create(:session_set, session: session, set_number: 1, reps: 20, duration_seconds: nil, rest_seconds_actual: nil)
      create(:session_set, session: session, set_number: 2, reps: 22, duration_seconds: nil, rest_seconds_actual: nil)
      create(:session_set, session: session, set_number: 3, reps: 18, duration_seconds: nil, rest_seconds_actual: nil)
    end

    it "computes pace per set as reps per minute (reps / effective duration * 60)" do
      expect(calculator.pace_per_set).to contain_exactly(20 * 60.0 / 300, 22 * 60.0 / 300, 18 * 60.0 / 300)
    end

    it "computes best pace as the max of the per-set paces" do
      expect(calculator.best_pace).to eq(22 * 60.0 / 300)
    end

    it "computes avg pace as the mean of the per-set paces" do
      expect(calculator.avg_pace).to eq((20 * 60.0 / 300 + 22 * 60.0 / 300 + 18 * 60.0 / 300) / 3)
    end

    it "computes total session output as sum(reps * weight)" do
      expect(calculator.total_session_output).to eq((20 + 22 + 18) * 10)
    end

    it "computes output per total time as kg/min using planned work+rest time" do
      expect(calculator.output_per_total_time).to eq(600 * 60.0 / 2700.0)
    end

    it "computes output per working time as kg/min using planned work time only" do
      expect(calculator.output_per_working_time).to eq(600 * 60.0 / 900.0)
    end
  end

  context "when a set overrides its actual duration and rest" do
    before do
      create(:session_set, session: session, set_number: 1, reps: 20, duration_seconds: 280, rest_seconds_actual: 650)
    end

    it "uses the actual measured values instead of the planned ones" do
      expect(calculator.pace_per_set).to contain_exactly(20 * 60.0 / 280)
      expect(calculator.output_per_working_time).to eq(200 * 60.0 / 280.0)
      expect(calculator.output_per_total_time).to eq(200 * 60.0 / 930.0)
    end
  end

  context "when a set has no reps recorded" do
    before do
      create(:session_set, session: session, set_number: 1, reps: 20)
      create(:session_set, session: session, set_number: 2, reps: nil)
    end

    it "excludes it from pace_per_set" do
      expect(calculator.pace_per_set.size).to eq(1)
    end
  end

  context "with no sets logged yet" do
    it "returns nil for pace metrics and zero for total output" do
      expect(calculator.best_pace).to be_nil
      expect(calculator.avg_pace).to be_nil
      expect(calculator.total_session_output).to eq(0)
      expect(calculator.output_per_total_time).to be_nil
      expect(calculator.output_per_working_time).to be_nil
    end
  end

  describe "#outputs" do
    it "returns raw, unformatted values" do
      create(:session_set, session: session, set_number: 1, reps: 20, duration_seconds: nil, rest_seconds_actual: nil)

      expect(calculator.outputs["Best pace"]).to eq(20 * 60.0 / 300)
      expect(calculator.outputs["Total output"]).to eq(200)
    end
  end

  describe "#display_outputs" do
    it "formats every metric, using an em dash for unavailable ones" do
      expect(calculator.display_outputs).to eq(
        "Best pace" => "—",
        "Avg pace" => "—",
        "Total output" => 0,
        "Output / total time" => "—",
        "Output / working time" => "—"
      )
    end

    it "rounds pace to 1 decimal and appends reps/min" do
      create(:session_set, session: session, set_number: 1, reps: 20, duration_seconds: nil, rest_seconds_actual: nil)

      outputs = calculator.display_outputs

      expect(outputs["Best pace"]).to eq("#{(20 * 60.0 / 300).round(1)} reps/min")
      expect(outputs["Total output"]).to eq(200)
    end

    it "rounds output rate metrics to 1 decimal and appends kg/min" do
      create(:session_set, session: session, set_number: 1, reps: 20, duration_seconds: nil, rest_seconds_actual: nil)

      outputs = calculator.display_outputs

      expect(outputs["Output / total time"]).to eq("#{(200 * 60.0 / 900.0).round(1)} kg/min")
      expect(outputs["Output / working time"]).to eq("#{(200 * 60.0 / 300.0).round(1)} kg/min")
    end
  end
end
