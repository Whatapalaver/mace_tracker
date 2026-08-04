module Progression
  # Chart-ready {series_label => {date => value}} data for a chosen output across every session
  # matching a structural signature (exercise + shape + the shape's structural key columns,
  # encoded as a single "300:300:5"-style string — see ComparabilityKey), replacing the
  # interval_work-only Progression::IntervalWorkPaceSeries. Weight is off by
  # default (each distinct weight becomes its own series, e.g. "8kg"/"10kg", so a weight change
  # over time stays visible); passing weight: locks to a single series for that weight.
  # granularity: "segment" (interval_work only) widens matching to every session containing a
  # work set of the given duration, regardless of its rest/set-count structure — best/avg pace
  # per session already collapses that session's own sets, so no per-set extraction is needed.
  class SignatureSeries
    def initialize(exercise:, session_shape:, structural_value:, output_label:, weight: nil,
                   benchmarks_only: false, granularity: "full")
      @exercise = exercise
      @session_shape = session_shape
      @structural_value = structural_value
      @output_label = output_label
      @weight = weight.presence
      @benchmarks_only = benchmarks_only
      @granularity = granularity
    end

    def to_h
      sessions = matching_sessions
      sessions = sessions.select { |session| session.weight_kg.to_f == @weight.to_f } if @weight

      series_by_weight = sessions.group_by { |session| "#{session.weight_kg}kg" }.transform_values do |group|
        group.each_with_object({}) do |session, series|
          value = Calculator.for(session).outputs[@output_label]
          series[session.date] = value if value
        end
      end

      # A weight with a single data point can't be drawn as a line — it's just a floating dot —
      # so it's dropped unless it's the only weight there is, in which case there's nothing else
      # to plot and a lone dot beats an empty chart.
      return series_by_weight if series_by_weight.size <= 1

      series_by_weight.reject { |_weight, series| series.size <= 1 }
    end

    private

    def matching_sessions
      criteria = ComparabilityKey.decode_structural_value(@session_shape.name, @structural_value, granularity: @granularity)
      scope = Session.where(exercise_id: @exercise.id, session_shape_id: @session_shape.id).where(criteria)
      scope = scope.where(is_benchmark: true) if @benchmarks_only
      scope.includes(:session_sets).order(:date).to_a
    end
  end
end
