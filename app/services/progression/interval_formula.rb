module Progression
  # Bridges interval_work's algebraic notation (e.g. "5(5mw+5mr)@10kg") and Session's plain
  # planned_* fields, using Progression::IntervalNotation::{Parser,Expander} for the actual
  # tokenizing/expansion. Session-level weight (the trailing "@Nkg") isn't part of warrior_timer's
  # grammar, so it's stripped here before handing the rest of the string to the ported parser.
  class IntervalFormula
    class ParseError < StandardError; end

    Result = Struct.new(:planned_weight_kg, :planned_work_seconds, :planned_rest_seconds,
                         :planned_sets, :work_segments, keyword_init: true)

    WEIGHT_SUFFIX = /\A(.*)@(\d+(?:\.\d+)?)kg\z/

    def self.parse(text)
      new(text).parse
    end

    def self.render(session)
      new(nil).render(session)
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
        planned_weight_kg: weight_text.to_f,
        planned_work_seconds: work_segments.first[:duration_seconds],
        planned_rest_seconds: rest_segments.first&.dig(:duration_seconds) || 0,
        planned_sets: work_segments.size,
        work_segments: work_segments
      )
    rescue IntervalNotation::Parser::ParseError => e
      raise ParseError, e.message
    end

    def render(session)
      body = format_duration(session.planned_work_seconds) + "w"
      if session.planned_rest_seconds.to_i.positive?
        body += "+#{format_duration(session.planned_rest_seconds)}r"
      end

      sets = session.planned_sets.to_i
      wrapped = sets > 1 ? "#{sets}(#{body})" : body

      "#{wrapped}@#{format_weight(session.planned_weight_kg)}kg"
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
