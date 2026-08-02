module Progression
  class ComparabilityKey
    class UnknownShapeError < StandardError; end

    def self.for(session)
      base = { exercise_id: session.exercise_id, session_shape_id: session.session_shape_id }

      case session.session_shape.name
      when SessionShape::INTERVAL_WORK
        base.merge(weight: session.weight_kg, work_duration: session.work_seconds,
                    rest_duration: session.rest_seconds, sets_count: session.sets_count)
      when SessionShape::FIXED_REPS_FOR_TIME
        base.merge(weight: session.weight_kg, reps: session.reps)
      when SessionShape::EMOM
        base.merge(weight: session.weight_kg, reps_per_minute: session.reps_per_minute)
      else
        raise UnknownShapeError, "No comparability key defined for session shape #{session.session_shape.name.inspect}"
      end
    end

    # Same key, minus weight — the "signature" a formula describes structurally, independent
    # of which weight it was performed at (weight is a separate, optional filter on top).
    def self.structural_for(session)
      self.for(session).except(:weight)
    end

    # The Session columns holding the structural (non-weight) key components for a shape — used
    # to query/group sessions by signature without needing a session instance in hand. Multiple
    # columns for interval_work: work duration alone can't distinguish a single 5-minute set
    # from 3 sets of 5 minutes with rest between, so rest and set count are part of the shape too.
    def self.structural_columns_for(shape_name)
      case shape_name
      when SessionShape::INTERVAL_WORK then [ :work_seconds, :rest_seconds, :sets_count ]
      when SessionShape::FIXED_REPS_FOR_TIME then [ :reps ]
      when SessionShape::EMOM then [ :reps_per_minute ]
      else
        raise UnknownShapeError, "No comparability key defined for session shape #{shape_name.inspect}"
      end
    end

    # Packs a session's structural columns into one URL-safe string (e.g. "300:300:5"), so a
    # multi-column signature like interval_work's can still round-trip through a single query
    # param the way a one-column shape's bare value ("108") already does.
    def self.encode_structural_value(session)
      structural_columns_for(session.session_shape.name).map { |col| session.public_send(col) }.join(":")
    end

    # The inverse of .encode_structural_value — {column => value} ready to pass straight to
    # Session.where.
    def self.decode_structural_value(shape_name, encoded)
      columns = structural_columns_for(shape_name)
      values = encoded.to_s.split(":").map(&:to_i)
      columns.zip(values).to_h
    end
  end
end
