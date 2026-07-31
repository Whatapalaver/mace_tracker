module Progression
  # Dispatches formula text to the right parser based on the session shape, mirroring
  # Progression::Calculator's REGISTRY-based dispatch pattern. The two dialects (interval
  # notation vs. the simpler reps notation) return different result shapes — callers already
  # branch on shape for the rest of the session-creation flow, so this stays a thin dispatcher
  # rather than normalizing both into one shape.
  class SessionFormula
    class ParseError < StandardError; end

    def self.parse(text, shape_name)
      case shape_name
      when SessionShape::INTERVAL_WORK
        IntervalFormula.parse(text)
      when SessionShape::FIXED_REPS_FOR_TIME, SessionShape::EMOM
        RepsFormula.parse(text)
      else
        raise ParseError, "No formula parser for session shape #{shape_name.inspect}"
      end
    rescue IntervalFormula::ParseError, RepsFormula::ParseError => e
      raise ParseError, e.message
    end
  end
end
