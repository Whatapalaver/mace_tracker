require "rails_helper"

RSpec.describe Progression::IntervalWorkPaceSeries do
  let(:exercise) { create(:exercise) }

  def session_with_set(date:, reps:, weight: 10, work_seconds: 300, exercise: nil)
    session = create(:session, exercise: exercise, date: date, planned_weight_kg: weight, planned_work_seconds: work_seconds)
    create(:session_set, session: session, set_number: 1, reps: reps, duration_seconds: work_seconds) if reps
    session
  end

  it "includes only sessions matching exercise, shape, weight, and work duration" do
    target = session_with_set(exercise: exercise, date: "2026-07-01", reps: 20)
    session_with_set(exercise: exercise, date: "2026-07-08", reps: 30, weight: 12) # different weight
    session_with_set(exercise: exercise, date: "2026-07-15", reps: 40, work_seconds: 180) # different work duration
    session_with_set(exercise: create(:exercise), date: "2026-07-22", reps: 50) # different exercise

    result = described_class.new(target).to_h

    expect(result["Best pace"].keys).to eq([ target.date ])
  end

  it "builds date-keyed series for best and avg pace" do
    older = session_with_set(exercise: exercise, date: "2026-07-01", reps: 20)
    newer = session_with_set(exercise: exercise, date: "2026-07-08", reps: 30)

    result = described_class.new(newer).to_h

    expect(result["Best pace"]).to eq(
      older.date => 20 / 300.0,
      newer.date => 30 / 300.0
    )
    expect(result["Avg pace"]).to eq(
      older.date => 20 / 300.0,
      newer.date => 30 / 300.0
    )
  end

  it "excludes sessions with no computable pace" do
    empty_session = session_with_set(exercise: exercise, date: "2026-07-01", reps: nil)
    with_reps = session_with_set(exercise: exercise, date: "2026-07-08", reps: 20)

    result = described_class.new(with_reps).to_h

    expect(result["Best pace"]).not_to have_key(empty_session.date)
    expect(result["Best pace"]).to have_key(with_reps.date)
  end
end
