require "rails_helper"

RSpec.describe Progression::SetsAndRepsCalculator do
  subject(:calculator) { described_class.new(session) }

  let(:session) { create(:session, :sets_and_reps, weight_kg: 10, reps: 24) }

  describe ".output_labels" do
    it "lists total reps and total output, with no time or pace metrics" do
      expect(described_class.output_labels).to eq([ "Total reps", "Total output" ])
    end
  end

  it "sums reps across all sets" do
    create(:session_set, session: session, set_number: 1, reps: 24)
    create(:session_set, session: session, set_number: 2, reps: 24)
    create(:session_set, session: session, set_number: 3, reps: 22)

    expect(calculator.total_reps).to eq(70)
  end

  it "computes total output as sum(reps * weight)" do
    create(:session_set, session: session, set_number: 1, reps: 24)
    create(:session_set, session: session, set_number: 2, reps: 24)

    expect(calculator.total_output).to eq(48 * 10)
  end

  it "returns 0 for both totals when nothing has been logged" do
    expect(calculator.total_reps).to eq(0)
    expect(calculator.total_output).to eq(0)
  end

  it "formats totals as whole numbers via display_outputs" do
    create(:session_set, session: session, set_number: 1, reps: 24)

    expect(calculator.display_outputs).to eq("Total reps" => 24, "Total output" => 240)
  end
end
