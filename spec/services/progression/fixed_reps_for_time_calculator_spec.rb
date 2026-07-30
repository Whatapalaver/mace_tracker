require "rails_helper"

RSpec.describe Progression::FixedRepsForTimeCalculator do
  subject(:calculator) { described_class.new(session) }

  let(:session) { create(:session, :fixed_reps_for_time, planned_weight_kg: 10, target_reps: 100) }

  context "with the effort logged" do
    before do
      create(:session_set, session: session, set_number: 1, reps: 100, duration_seconds: 240)
    end

    it "reports the total time" do
      expect(calculator.time_seconds).to eq(240)
    end

    it "computes pace as reps / duration" do
      expect(calculator.pace).to eq(100 / 240.0)
    end

    it "formats both metrics via display_outputs" do
      expect(calculator.display_outputs).to eq(
        "Time (sec)" => 240,
        "Pace" => (100 / 240.0).round(3)
      )
    end
  end

  context "when nothing has been logged yet" do
    it "returns nil for both metrics" do
      expect(calculator.time_seconds).to be_nil
      expect(calculator.pace).to be_nil
    end

    it "shows an em dash for both metrics" do
      expect(calculator.display_outputs).to eq("Time (sec)" => "—", "Pace" => "—")
    end
  end
end
