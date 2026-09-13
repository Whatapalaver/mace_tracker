module Progression
  # Parses the comma-separated reps-list text used when logging/editing a session's sets — e.g.
  # "200, 189, 199" (every set falls back to the session's own weight_kg) or "100@6, 100@6, 50@8"
  # (per-set weight override, same kg unit as Session#weight_kg). Each entry is "<reps>" or
  # "<reps>@<weight>"; weight is optional per entry and independent per set, so a bare list and an
  # overridden entry can be mixed freely within the same session.
  class RepsList
    class ParseError < StandardError; end

    Entry = Struct.new(:reps, :weight_kg, keyword_init: true)

    ENTRY_PATTERN = /\A(\d+)(?:@(\d+(?:\.\d+)?))?\z/

    # expected_count is interval_work's own signature-implied set count (e.g. 50 for
    # "50(15w+15r)") — when a single entry is given against a multi-set signature, it's repeated
    # to fill every set rather than treated as a mismatch, so a uniform-reps interval session
    # (the common case — the same target every round) never needs typing that value out N times.
    # A genuine list of more than one entry is never expanded, even if its length still doesn't
    # match — that mismatch is a real error for the caller to report, not something to guess at.
    def self.parse(text, expected_count: nil)
      values = text.to_s.split(",").map(&:strip).reject(&:empty?)
      raise ParseError, "At least one rep value is required" if values.empty?

      entries = values.map do |value|
        match = value.match(ENTRY_PATTERN)
        raise ParseError, "Reps must be a comma-separated list like 200, 189 or 100@6, 50@8" unless match

        Entry.new(reps: match[1].to_i, weight_kg: match[2]&.to_f)
      end

      if expected_count && expected_count > 1 && entries.size == 1
        Array.new(expected_count, entries.first)
      else
        entries
      end
    end
  end
end
