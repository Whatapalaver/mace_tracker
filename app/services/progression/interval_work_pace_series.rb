module Progression
  class IntervalWorkPaceSeries
    def initialize(session)
      @session = session
    end

    def to_h
      { "Best pace" => series(:best_pace), "Avg pace" => series(:avg_pace) }
    end

    private

    attr_reader :session

    def matching_sessions
      key = ComparabilityKey.for(session)

      Session.where(
        exercise_id: key[:exercise_id],
        session_shape_id: key[:session_shape_id],
        planned_weight_kg: key[:weight],
        planned_work_seconds: key[:work_duration]
      ).includes(:session_sets).order(:date)
    end

    def series(metric)
      matching_sessions.each_with_object({}) do |matching_session, hash|
        value = Calculator.for(matching_session).public_send(metric)
        hash[matching_session.date] = value if value
      end
    end
  end
end
