module Progression
  class ComparabilityKey
    class UnknownShapeError < StandardError; end

    def self.for(session)
      base = { exercise_id: session.exercise_id, session_shape_id: session.session_shape_id }

      case session.session_shape.name
      when SessionShape::INTERVAL_WORK
        base.merge(weight: session.weight_kg, work_duration: session.work_seconds)
      when SessionShape::FIXED_REPS_FOR_TIME
        base.merge(weight: session.weight_kg, target_reps: session.target_reps)
      when SessionShape::EMOM
        base.merge(weight: session.weight_kg, target_reps_per_minute: session.target_reps_per_minute)
      else
        raise UnknownShapeError, "No comparability key defined for session shape #{session.session_shape.name.inspect}"
      end
    end

    # Same key, minus weight — the "signature" a formula describes structurally, independent
    # of which weight it was performed at (weight is a separate, optional filter on top).
    def self.structural_for(session)
      self.for(session).except(:weight)
    end

    # The Session column holding the one structural (non-weight) key component for a shape —
    # used to query/group sessions by signature without needing a session instance in hand.
    def self.structural_column_for(shape_name)
      case shape_name
      when SessionShape::INTERVAL_WORK then :work_seconds
      when SessionShape::FIXED_REPS_FOR_TIME then :target_reps
      when SessionShape::EMOM then :target_reps_per_minute
      else
        raise UnknownShapeError, "No comparability key defined for session shape #{shape_name.inspect}"
      end
    end
  end
end
