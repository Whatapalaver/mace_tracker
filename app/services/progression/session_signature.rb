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

    # Infers interval_work vs sets_and_reps from bare signature text with no shape chosen up
    # front — used by the primary log-session form, which has no shape picker at all. Tries the
    # real interval grammar first; success means interval_work, and the parsed attrs come along
    # for free. Any failure falls back to sets_and_reps — safe by construction, not coincidence,
    # since every segment in IntervalNotation::Parser's grammar requires a trailing w/r type
    # letter, so a bare integer can never be misread as interval notation. On a genuine typo
    # (e.g. "5(5mw"), the interval parser's own error is more diagnostic than the generic "expected
    # a whole number" would be, so that's what surfaces.
    # fixed_reps_for_time/emom are deliberately never inferred here — their bare notation is
    # textually identical to sets_and_reps's — they're only reachable through the log form's
    # explicit "different shape" section, which calls .parse directly with a known shape_name.
    def self.parse_inferred(text)
      result = IntervalFormula.parse_without_weight(text)
      [ SessionShape::INTERVAL_WORK,
        { work_seconds: result.work_seconds, rest_seconds: result.rest_seconds, sets_count: result.sets_count } ]
    rescue IntervalFormula::ParseError => interval_error
      begin
        [ SessionShape::SETS_AND_REPS, { reps: parse_number(text) } ]
      rescue ParseError
        raise ParseError, interval_error.message
      end
    end
  end
end
