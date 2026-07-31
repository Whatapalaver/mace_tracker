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
      new(nil).render(session)
    end

    def self.render_without_weight(session)
      new(nil).body(session)
    end

    def initialize(text)
      @text = text.to_s.strip
    end

    def parse
      match = @text.match(WEIGHT_SUFFIX)
      raise ParseError, "Missing weight — end the formula with e.g. @10kg" unless match

      formula, weight_text = match[1], match[2]

      segments = IntervalNotation::Expander.new(IntervalNotation::Parser.new(formula).parse).expand
      work_segments = segments.select { |s| s[:segment_type] == :work }
      rest_segments = segments.select { |s| s[:segment_type] == :rest }

      raise ParseError, "Formula must include at least one work segment" if work_segments.empty?

      Result.new(
        weight_kg: weight_text.to_f,
        work_seconds: work_segments.first[:duration_seconds],
        rest_seconds: rest_segments.first&.dig(:duration_seconds) || 0,
        sets_count: work_segments.size,
        work_segments: work_segments
      )
    rescue IntervalNotation::Parser::ParseError => e
      raise ParseError, e.message
    end

    def render(session)
      "#{body(session)}@#{format_weight(session.weight_kg)}kg"
    end

    def body(session)
      segment = format_duration(session.work_seconds) + "w"
      if session.rest_seconds.to_i.positive?
        segment += "+#{format_duration(session.rest_seconds)}r"
      end

      sets = session.sets_count.to_i
      sets > 1 ? "#{sets}(#{segment})" : segment
    end

    private

    def format_duration(seconds)
      seconds = seconds.to_i
      seconds.positive? && (seconds % 60).zero? ? "#{seconds / 60}m" : seconds.to_s
    end

    def format_weight(weight)
      value = weight.to_f
      value == value.to_i ? value.to_i.to_s : value.to_s
    end
  end
end
