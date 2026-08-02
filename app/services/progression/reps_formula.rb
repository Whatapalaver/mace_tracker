module Progression
  # Small dedicated parser for fixed_reps_for_time/emom's notation: "N(X@Wkg)" — N = actual
  # sets/rounds, X = reps per set/round, W = weight. Deliberately not built on
  # Progression::IntervalNotation — that grammar requires w/r type letters and doesn't fit a
  # bare-number-per-block pattern. Shape-agnostic by design: the caller maps `reps` onto
  # reps (fixed_reps_for_time) or reps_per_minute (emom).
  class RepsFormula
    class ParseError < StandardError; end

    Result = Struct.new(:count, :reps, :weight_kg, keyword_init: true)

    PATTERN = /\A(\d+)\((\d+)@(\d+(?:\.\d+)?)kg\)\z/

    def self.parse(text)
      match = text.to_s.strip.match(PATTERN)
      raise ParseError, "Expected format like 5(108@10kg)" unless match

      count = match[1].to_i
      reps = match[2].to_i
      raise ParseError, "Count and reps must be greater than zero" if count.zero? || reps.zero?

      Result.new(count: count, reps: reps, weight_kg: match[3].to_f)
    end

    def self.render(count:, reps:, weight_kg:)
      "#{count}(#{reps}@#{format_weight(weight_kg)}kg)"
    end

    def self.format_weight(weight)
      value = weight.to_f
      value == value.to_i ? value.to_i.to_s : value.to_s
    end
  end
end
