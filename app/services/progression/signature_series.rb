module Progression
  # Chart-ready {series_label => {date => value}} data for a chosen output across every session
  # matching a structural signature (exercise + shape + the shape's structural key columns,
  # encoded as a single "300:300:5"-style string — see ComparabilityKey), replacing the
  # interval_work-only Progression::IntervalWorkPaceSeries. Weight is off by
  # default (each distinct weight becomes its own series, e.g. "8kg"/"10kg", so a weight change
  # over time stays visible); passing weight: locks to a single series for that weight. A weight
  # tried only once still gets its own single-point series here (unlike the lifetime "max reps by
  # weight" chart, which drops those) — one-off weights within a specific signature are exactly
  # the kind of outlier worth seeing, and there are usually few enough of them per signature that
  # they don't clutter the chart the way they can across an exercise's entire history.
  # granularity: "segment" (interval_work only) widens matching to every session containing a
  # work set of the given duration, regardless of its rest/set-count structure — best/avg pace
  # per session already collapses that session's own sets, so no per-set extraction is needed.
  class SignatureSeries
    def initialize(exercise:, session_shape:, structural_value:, output_label:, weight: nil,
                   benchmarks_only: false, granularity: "full", tool: nil)
      @exercise = exercise
      @session_shape = session_shape
      @structural_value = structural_value
      @output_label = output_label
      @weight = weight.presence
      @benchmarks_only = benchmarks_only
      @granularity = granularity
      @tool = tool
    end

    def to_h
      sessions = matching_sessions
      sessions = sessions.select { |session| session.weight_kg.to_f == @weight.to_f } if @weight

      sessions.group_by { |session| "#{session.weight_kg}kg" }.transform_values do |group|
        group.each_with_object({}) do |session, series|
          value = Calculator.for(session).outputs[@output_label]
          series[session.date] = value if value
        end
      end
    end

    private

    def matching_sessions
      criteria = ComparabilityKey.decode_structural_value(@session_shape.name, @structural_value, granularity: @granularity)
      scope = Session.where(exercise_id: @exercise.id, session_shape_id: @session_shape.id).where(criteria)
      scope = scope.where(is_benchmark: true) if @benchmarks_only
      scope = scope.where(tool_id: @tool.id) if @tool
      scope.includes(:session_sets).order(:date).to_a
    end
  end
end
