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

    def self.parse(text)
      values = text.to_s.split(",").map(&:strip).reject(&:empty?)
      raise ParseError, "At least one rep value is required" if values.empty?

      values.map do |value|
        match = value.match(ENTRY_PATTERN)
        raise ParseError, "Reps must be a comma-separated list like 200, 189 or 100@6, 50@8" unless match

        Entry.new(reps: match[1].to_i, weight_kg: match[2]&.to_f)
      end
    end
  end
end
