require "rails_helper"

RSpec.describe Progression::LifetimeStats do
  let(:mace) { create(:exercise, name: "360", equipment: create(:equipment, name: "Mace")) }
  let(:kettlebell) { create(:exercise, name: "Swing", equipment: create(:equipment, name: "Kettlebell")) }

  def logged_set(exercise:, date:, reps:, weight:)
    session = create(:session, exercise: exercise, date: date, weight_kg: weight)
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

  describe "#reps_by_period and #volume_by_period" do
    it "defaults to daily totals, keyed by date, in chronological order, zero-filling gaps" do
      logged_set(exercise: mace, date: "2026-07-01", reps: 20, weight: 10)
      logged_set(exercise: mace, date: "2026-07-03", reps: 30, weight: 10)

      stats = described_class.new(exercise: mace)

      expect(stats.reps_by_period).to eq(
        Date.new(2026, 7, 1) => 20,
        Date.new(2026, 7, 2) => 0,
        Date.new(2026, 7, 3) => 30
      )
      expect(stats.volume_by_period).to eq(
        Date.new(2026, 7, 1) => 200,
        Date.new(2026, 7, 2) => 0,
        Date.new(2026, 7, 3) => 300
      )
    end

    it "sums multiple sets on the same date into one daily total" do
      session = create(:session, exercise: mace, date: "2026-07-01", weight_kg: 10)
      create(:session_set, session: session, set_number: 1, reps: 20)
      create(:session_set, session: session, set_number: 2, reps: 10)

      stats = described_class.new(exercise: mace)

      expect(stats.reps_by_period).to eq(Date.new(2026, 7, 1) => 30)
    end

    it "buckets by week when period is weekly" do
      logged_set(exercise: mace, date: "2026-07-01", reps: 20, weight: 10) # Wednesday
      logged_set(exercise: mace, date: "2026-07-02", reps: 10, weight: 10) # same week
      logged_set(exercise: mace, date: "2026-07-09", reps: 15, weight: 10) # next week

      stats = described_class.new(exercise: mace, period: "weekly")

      expect(stats.reps_by_period).to eq(
        Date.new(2026, 7, 1).beginning_of_week => 30,
        Date.new(2026, 7, 9).beginning_of_week => 15
      )
    end

    it "buckets by month when period is monthly" do
      logged_set(exercise: mace, date: "2026-07-01", reps: 20, weight: 10)
      logged_set(exercise: mace, date: "2026-07-28", reps: 10, weight: 10)
      logged_set(exercise: mace, date: "2026-08-01", reps: 15, weight: 10)

      stats = described_class.new(exercise: mace, period: "monthly")

      expect(stats.reps_by_period).to eq(
        Date.new(2026, 7, 1) => 30,
        Date.new(2026, 8, 1) => 15
      )
    end

    it "buckets by year when period is yearly" do
      logged_set(exercise: mace, date: "2026-01-15", reps: 20, weight: 10)
      logged_set(exercise: mace, date: "2026-12-15", reps: 10, weight: 10)
      logged_set(exercise: mace, date: "2027-01-15", reps: 15, weight: 10)

      stats = described_class.new(exercise: mace, period: "yearly")

      expect(stats.reps_by_period).to eq(
        Date.new(2026, 1, 1) => 30,
        Date.new(2027, 1, 1) => 15
      )
    end

    it "falls back to daily for an unrecognized period" do
      logged_set(exercise: mace, date: "2026-07-01", reps: 20, weight: 10)

      stats = described_class.new(exercise: mace, period: "bogus")

      expect(stats.reps_by_period).to eq(Date.new(2026, 7, 1) => 20)
    end

    it "shows a skipped month as a zero-value bucket rather than omitting it" do
      logged_set(exercise: mace, date: "2026-01-15", reps: 20, weight: 10)
      logged_set(exercise: mace, date: "2026-03-15", reps: 15, weight: 10) # February skipped entirely

      stats = described_class.new(exercise: mace, period: "monthly")

      expect(stats.reps_by_period).to eq(
        Date.new(2026, 1, 1) => 20,
        Date.new(2026, 2, 1) => 0,
        Date.new(2026, 3, 1) => 15
      )
    end

    it "returns an empty series when nothing has been logged, without erroring" do
      stats = described_class.new(exercise: mace)

      expect(stats.reps_by_period).to eq({})
    end
  end

  describe "#max_reps_by_weight_and_period" do
    it "returns one series per weight, keyed by period, holding the max reps in any single set" do
      session = create(:session, exercise: mace, date: "2026-07-01", weight_kg: 10)
      create(:session_set, session: session, set_number: 1, reps: 20)
      create(:session_set, session: session, set_number: 2, reps: 30)
      logged_set(exercise: mace, date: "2026-07-05", reps: 28, weight: 10)
      logged_set(exercise: mace, date: "2026-07-01", reps: 15, weight: 8)
      logged_set(exercise: mace, date: "2026-07-03", reps: 25, weight: 8)

      stats = described_class.new(exercise: mace)

      expect(stats.max_reps_by_weight_and_period).to eq(
        "8.0kg" => {
          Date.new(2026, 7, 1) => 15,
          Date.new(2026, 7, 3) => 25
        },
        "10.0kg" => {
          Date.new(2026, 7, 1) => 30,
          Date.new(2026, 7, 5) => 28
        }
      )
    end

    it "does not zero-fill a period where a weight wasn't lifted, unlike reps_by_period" do
      logged_set(exercise: mace, date: "2026-01-15", reps: 20, weight: 10)
      logged_set(exercise: mace, date: "2026-03-15", reps: 15, weight: 10) # February skipped entirely

      stats = described_class.new(exercise: mace, period: "monthly")

      expect(stats.max_reps_by_weight_and_period).to eq(
        "10.0kg" => {
          Date.new(2026, 1, 1) => 20,
          Date.new(2026, 3, 1) => 15
        }
      )
    end

    it "drops a weight with only one data point when other weights have more than one" do
      logged_set(exercise: mace, date: "2026-07-01", reps: 20, weight: 10)
      logged_set(exercise: mace, date: "2026-07-05", reps: 22, weight: 10)
      logged_set(exercise: mace, date: "2026-07-01", reps: 15, weight: 12) # only ever tried once

      stats = described_class.new(exercise: mace)

      expect(stats.max_reps_by_weight_and_period.keys).to eq([ "10.0kg" ])
    end

    it "keeps a lone weight's single data point when it's the only weight logged" do
      logged_set(exercise: mace, date: "2026-07-01", reps: 20, weight: 10)

      stats = described_class.new(exercise: mace)

      expect(stats.max_reps_by_weight_and_period).to eq("10.0kg" => { Date.new(2026, 7, 1) => 20 })
    end
  end

  describe "#personal_bests" do
    it "returns the max reps and its date for each weight, sorted heaviest first" do
      logged_set(exercise: mace, date: "2026-07-01", reps: 20, weight: 10)
      logged_set(exercise: mace, date: "2026-07-05", reps: 25, weight: 10)
      logged_set(exercise: mace, date: "2026-06-01", reps: 35, weight: 8) # 8*35=280 beats 10*25=250

      stats = described_class.new(exercise: mace)

      expect(stats.personal_bests).to eq(
        [
          { weight: 10, date: Date.new(2026, 7, 5), reps: 25 },
          { weight: 8, date: Date.new(2026, 6, 1), reps: 35 }
        ]
      )
    end

    it "breaks a tie by the earliest date it was achieved" do
      logged_set(exercise: mace, date: "2026-07-05", reps: 20, weight: 10)
      logged_set(exercise: mace, date: "2026-07-01", reps: 20, weight: 10)

      stats = described_class.new(exercise: mace)

      expect(stats.personal_bests).to eq([ { weight: 10, date: Date.new(2026, 7, 1), reps: 20 } ])
    end

    it "returns an empty array when nothing has been logged" do
      stats = described_class.new(exercise: mace)

      expect(stats.personal_bests).to eq([])
    end

    it "drops a lighter weight whose volume is exceeded by a heavier weight's" do
      logged_set(exercise: mace, date: "2026-07-01", reps: 30, weight: 10) # volume 300
      logged_set(exercise: mace, date: "2026-06-01", reps: 20, weight: 8) # volume 160, exceeded

      stats = described_class.new(exercise: mace)

      expect(stats.personal_bests).to eq([ { weight: 10, date: Date.new(2026, 7, 1), reps: 30 } ])
    end

    it "keeps a lighter weight whose volume exactly ties a heavier weight's" do
      logged_set(exercise: mace, date: "2026-07-01", reps: 20, weight: 10) # volume 200
      logged_set(exercise: mace, date: "2026-06-01", reps: 25, weight: 8) # volume 200, not exceeded

      stats = described_class.new(exercise: mace)

      expect(stats.personal_bests).to eq(
        [
          { weight: 10, date: Date.new(2026, 7, 1), reps: 20 },
          { weight: 8, date: Date.new(2026, 6, 1), reps: 25 }
        ]
      )
    end

    it "compares each weight against the best volume among all heavier weights, not just the one directly above it" do
      logged_set(exercise: mace, date: "2026-05-01", reps: 10, weight: 12) # volume 120
      logged_set(exercise: mace, date: "2026-06-01", reps: 20, weight: 10) # volume 200
      logged_set(exercise: mace, date: "2026-07-01", reps: 15, weight: 8) # volume 120, exceeded by 10kg's 200

      stats = described_class.new(exercise: mace)

      expect(stats.personal_bests).to eq(
        [
          { weight: 12, date: Date.new(2026, 5, 1), reps: 10 },
          { weight: 10, date: Date.new(2026, 6, 1), reps: 20 }
        ]
      )
    end
  end
end
