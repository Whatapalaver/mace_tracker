module Progression
  # Parses the weight-agnostic signature text shown/edited in the history table (e.g.
  # "3(5mw+5mr)" for interval_work, a bare "108" for fixed_reps_for_time/emom/sets_and_reps)
  # into the session-level attributes it describes. Dispatches by shape the same way
  # SessionFormula does for the full (weighted) notation used when logging a new session.
  class SessionSignature
    class ParseError < StandardError; end

    def self.parse(text, shape_name)
      case shape_name
      when SessionShape::INTERVAL_WORK
        result = IntervalFormula.parse_without_weight(text)
        { work_seconds: result.work_seconds, rest_seconds: result.rest_seconds, sets_count: result.sets_count }
      when SessionShape::FIXED_REPS_FOR_TIME, SessionShape::SETS_AND_REPS
        { reps: parse_number(text) }
      when SessionShape::EMOM
        { reps_per_minute: parse_number(text) }
      else
        raise ParseError, "No signature format defined for session shape #{shape_name.inspect}"
      end
    rescue IntervalFormula::ParseError => e
      raise ParseError, e.message
    end

    def self.parse_number(text)
      Integer(text.to_s.strip)
    rescue ArgumentError, TypeError
      raise ParseError, "Expected a whole number"
    end
  end
end
