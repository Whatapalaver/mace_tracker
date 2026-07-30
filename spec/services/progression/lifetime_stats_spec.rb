require "rails_helper"

RSpec.describe Progression::LifetimeStats do
  let(:mace) { create(:exercise, name: "Mace 360") }
  let(:kettlebell) { create(:exercise, name: "Kettlebell Swing") }

  def logged_set(exercise:, date:, reps:, weight:)
    session = create(:session, exercise: exercise, date: date, planned_weight_kg: weight)
    create(:session_set, session: session, set_number: 1, reps: reps, weight_kg: nil)
  end

  describe "with no exercise filter" do
    subject(:stats) { described_class.new }

    it "totals reps and volume across every exercise" do
      logged_set(exercise: mace, date: "2026-07-01", reps: 20, weight: 10)
      logged_set(exercise: kettlebell, date: "2026-07-02", reps: 15, weight: 16)

      expect(stats.total_reps).to eq(35)
      expect(stats.total_volume).to eq(20 * 10 + 15 * 16)
    end

    it "returns 0 when nothing has been logged" do
      expect(stats.total_reps).to eq(0)
      expect(stats.total_volume).to eq(0)
    end
  end

  describe "filtered by exercise" do
    it "only counts sets for that exercise" do
      logged_set(exercise: mace, date: "2026-07-01", reps: 20, weight: 10)
      logged_set(exercise: kettlebell, date: "2026-07-02", reps: 15, weight: 16)

      stats = described_class.new(exercise: mace)

      expect(stats.total_reps).to eq(20)
      expect(stats.total_volume).to eq(200)
    end
  end

  describe "#cumulative_reps_by_date and #cumulative_volume_by_date" do
    it "build a running total keyed by date, in chronological order" do
      logged_set(exercise: mace, date: "2026-07-01", reps: 20, weight: 10)
      logged_set(exercise: mace, date: "2026-07-08", reps: 30, weight: 10)

      stats = described_class.new(exercise: mace)

      expect(stats.cumulative_reps_by_date).to eq(
        Date.new(2026, 7, 1) => 20,
        Date.new(2026, 7, 8) => 50
      )
      expect(stats.cumulative_volume_by_date).to eq(
        Date.new(2026, 7, 1) => 200,
        Date.new(2026, 7, 8) => 500
      )
    end

    it "accumulates multiple sets on the same date into one running total" do
      session = create(:session, exercise: mace, date: "2026-07-01", planned_weight_kg: 10)
      create(:session_set, session: session, set_number: 1, reps: 20)
      create(:session_set, session: session, set_number: 2, reps: 10)

      stats = described_class.new(exercise: mace)

      expect(stats.cumulative_reps_by_date).to eq(Date.new(2026, 7, 1) => 30)
    end
  end
end
