module Progression
  class IntervalWorkPaceSeries
    def initialize(session, benchmarks_only: false)
      @session = session
      @benchmarks_only = benchmarks_only
    end

    def to_h
      { "Best pace" => series(:best_pace), "Avg pace" => series(:avg_pace) }
    end

    private

    attr_reader :session, :benchmarks_only

    def matching_sessions
      key = ComparabilityKey.for(session)

      scope = Session.where(
        exercise_id: key[:exercise_id],
        session_shape_id: key[:session_shape_id],
        planned_weight_kg: key[:weight],
        planned_work_seconds: key[:work_duration]
      )
      scope = scope.where(is_benchmark: true) if benchmarks_only
      scope.includes(:session_sets).order(:date)
    end

    def series(metric)
      matching_sessions.each_with_object({}) do |matching_session, hash|
        value = Calculator.for(matching_session).public_send(metric)
        hash[matching_session.date] = value if value
      end
    end
  end
end
