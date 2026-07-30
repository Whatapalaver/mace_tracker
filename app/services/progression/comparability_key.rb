module Progression
  class ComparabilityKey
    class UnknownShapeError < StandardError; end

    def self.for(session)
      base = { exercise_id: session.exercise_id, session_shape_id: session.session_shape_id }

      case session.session_shape.name
      when SessionShape::INTERVAL_WORK
        base.merge(weight: session.planned_weight_kg, work_duration: session.planned_work_seconds)
      else
        raise UnknownShapeError, "No comparability key defined for session shape #{session.session_shape.name.inspect}"
      end
    end
  end
end
