module Progression
  class BaseCalculator
    attr_reader :session

    def initialize(session)
      @session = session
    end

    def total_volume
      session_sets.sum { |set| (set.reps || 0) * (set.effective_weight_kg || 0) }
    end

    # Ordered {label => raw numeric value or nil} pairs, implemented per shape.
    # The single source of truth for both #display_outputs (formatted) and charting (raw).
    def outputs
      raise NotImplementedError, "#{self.class} must implement #outputs"
    end

    def display_outputs
      outputs.to_h { |label, value| [ label, format_metric(value, precision: precision_for(label)) ] }
    end

    private

    def session_sets
      session.session_sets
    end

    # Subclasses override to give specific outputs (e.g. whole-number totals) less precision.
    def precision_for(_label)
      3
    end

    def format_metric(value, precision: 3)
      return "—" if value.nil?

      value.round(precision)
    end
  end
end
