require "rails_helper"

RSpec.describe Progression::BaseCalculator do
  subject(:calculator) { described_class.new(session) }

  let(:session) { create(:session, planned_weight_kg: 10) }

  describe "#total_volume" do
    it "sums reps times effective weight across all sets" do
      create(:session_set, session: session, reps: 20, weight_kg: nil)
      create(:session_set, session: session, reps: 10, weight_kg: 12)

      expect(calculator.total_volume).to eq(20 * 10 + 10 * 12)
    end

    it "returns 0 when there are no sets" do
      expect(calculator.total_volume).to eq(0)
    end

    it "treats a set with no reps as contributing 0" do
      create(:session_set, session: session, reps: nil)

      expect(calculator.total_volume).to eq(0)
    end
  end

  describe "#outputs" do
    it "raises NotImplementedError, requiring subclasses to define it" do
      expect { calculator.outputs }.to raise_error(NotImplementedError)
    end
  end

  describe "#display_outputs" do
    it "raises NotImplementedError since it delegates to #outputs" do
      expect { calculator.display_outputs }.to raise_error(NotImplementedError)
    end
  end
end
