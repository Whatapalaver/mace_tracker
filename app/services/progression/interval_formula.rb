module Progression
  # Bridges interval_work's algebraic notation (e.g. "5(5mw+5mr)@10kg") and Session's plain
  # weight_kg/work_seconds/rest_seconds/sets_count fields, using
  # Progression::IntervalNotation::{Parser,Expander} for the actual tokenizing/expansion.
  # Session-level weight (the trailing "@Nkg") isn't part of warrior_timer's grammar, so it's
  # stripped here before handing the rest of the string to the ported parser.
  class IntervalFormula
    class ParseError < StandardError; end

    Result = Struct.new(:weight_kg, :work_seconds, :rest_seconds,
                         :sets_count, :work_segments, keyword_init: true)

    WEIGHT_SUFFIX = /\A(.*)@(\d+(?:\.\d+)?)kg\z/

    def self.parse(text)
      new(text).parse
    end

    def self.render(session)
      "#{render_without_weight(session)}@#{format_weight(session.weight_kg)}kg"
    end

    def self.render_without_weight(session)
      render_without_weight_values(work_seconds: session.work_seconds, rest_seconds: session.rest_seconds,
                                    sets_count: session.sets_count)
    end

    # Same as .render_without_weight, but from plain values instead of a Session/BenchmarkPreset
    # instance — for callers (like the stats signature browser) that only have plucked columns.
    def self.render_without_weight_values(work_seconds:, rest_seconds:, sets_count:)
      segment = format_duration(work_seconds) + "w"
      segment += "+#{format_duration(rest_seconds)}r" if rest_seconds.to_i.positive?

      sets_count.to_i > 1 ? "#{sets_count}(#{segment})" : segment
    end

    # Parses the weight-agnostic body only (no "@Wkg" suffix) — for editing a session's
    # signature independently of its weight.
    def self.parse_without_weight(text)
      segments = IntervalNotation::Expander.new(IntervalNotation::Parser.new(text.to_s.strip).parse).expand
      work_segments = segments.select { |s| s[:segment_type] == :work }
      rest_segments = segments.select { |s| s[:segment_type] == :rest }

      raise ParseError, "Formula must include at least one work segment" if work_segments.empty?

      Result.new(
        work_seconds: work_segments.first[:duration_seconds],
        rest_seconds: rest_segments.first&.dig(:duration_seconds) || 0,
        sets_count: work_segments.size,
        work_segments: work_segments
      )
    rescue IntervalNotation::Parser::ParseError => e
      raise ParseError, e.message
    end

    def self.format_duration(seconds)
      seconds = seconds.to_i
      seconds.positive? && (seconds % 60).zero? ? "#{seconds / 60}m" : seconds.to_s
    end

    def self.format_weight(weight)
      value = weight.to_f
      value == value.to_i ? value.to_i.to_s : value.to_s
    end

    def initialize(text)
      @text = text.to_s.strip
    end

    def parse
      match = @text.match(WEIGHT_SUFFIX)
      raise ParseError, "Missing weight — end the formula with e.g. @10kg" unless match

      formula, weight_text = match[1], match[2]
      result = self.class.parse_without_weight(formula)
      result.weight_kg = weight_text.to_f
      result
    end
  end
end
