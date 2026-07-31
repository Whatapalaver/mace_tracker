require "rails_helper"

RSpec.describe Progression::SignatureSeries do
  let(:exercise) { create(:exercise) }
  let(:interval_work_shape) { create(:session_shape, :interval_work) }

  def series_for(**overrides)
    described_class.new(
      exercise: exercise, session_shape: interval_work_shape,
      structural_value: 300, output_label: "Best pace",
      **overrides
    ).to_h
  end

  def session_with_set(date:, reps:, weight:, work_seconds: 300, is_benchmark: false)
    session = create(:session, exercise: exercise, session_shape: interval_work_shape, date: date,
                                planned_weight_kg: weight, planned_work_seconds: work_seconds,
                                is_benchmark: is_benchmark)
    create(:session_set, session: session, set_number: 1, reps: reps, duration_seconds: work_seconds)
    session
  end

  it "groups sessions into one series per weight when weight is not locked" do
    light = session_with_set(date: "2026-07-01", reps: 20, weight: 8)
    heavy = session_with_set(date: "2026-07-08", reps: 25, weight: 10)

    result = series_for

    expect(result.keys).to contain_exactly("8.0kg", "10.0kg")
    expect(result["8.0kg"]).to eq(light.date => 20 / 300.0)
    expect(result["10.0kg"]).to eq(heavy.date => 25 / 300.0)
  end

  it "restricts to a single series when weight is locked" do
    session_with_set(date: "2026-07-01", reps: 20, weight: 8)
    heavy = session_with_set(date: "2026-07-08", reps: 25, weight: 10)

    result = series_for(weight: "10")

    expect(result.keys).to contain_exactly("10.0kg")
    expect(result["10.0kg"]).to eq(heavy.date => 25 / 300.0)
  end

  it "excludes sessions with a different structural value" do
    session_with_set(date: "2026-07-01", reps: 20, weight: 10, work_seconds: 180)
    matching = session_with_set(date: "2026-07-08", reps: 25, weight: 10, work_seconds: 300)

    result = series_for

    expect(result["10.0kg"]).to eq(matching.date => 25 / 300.0)
  end

  it "uses the requested output label" do
    session_with_set(date: "2026-07-01", reps: 20, weight: 10)

    result = series_for(output_label: "Total output")

    expect(result["10.0kg"].values.first).to eq(200)
  end

  it "restricts to benchmark sessions when benchmarks_only is set" do
    session_with_set(date: "2026-07-01", reps: 20, weight: 10, is_benchmark: false)
    benchmark = session_with_set(date: "2026-07-08", reps: 25, weight: 10, is_benchmark: true)

    result = series_for(benchmarks_only: true)

    expect(result["10.0kg"].keys).to eq([ benchmark.date ])
  end
end
