require "rails_helper"

RSpec.describe Progression::EmomCalculator do
  subject(:calculator) { described_class.new(session) }

  let(:session) { create(:session, :emom, weight_kg: 10, reps_per_minute: 20) }

  describe ".output_labels" do
    it "lists the single output key" do
      expect(described_class.output_labels).to eq([ "Sets completed" ])
    end
  end

  it "counts the sets logged before failure" do
    create(:session_set, session: session, set_number: 1)
    create(:session_set, session: session, set_number: 2)
    create(:session_set, session: session, set_number: 3)

    expect(calculator.total_sets_completed).to eq(3)
  end

  it "returns 0 when no sets have been logged" do
    expect(calculator.total_sets_completed).to eq(0)
  end

  it "formats the count via display_outputs" do
    create(:session_set, session: session, set_number: 1)

    expect(calculator.display_outputs).to eq("Sets completed" => 1)
  end
end
