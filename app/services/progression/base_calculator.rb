module Progression
  class BaseCalculator
    attr_reader :session

    def initialize(session)
      @session = session
    end

    def total_volume
      session_sets.sum { |set| (set.reps || 0) * (set.effective_weight_kg || 0) }
    end

    # Ordered {label => formatted value} pairs for display, implemented per shape.
    def display_outputs
      raise NotImplementedError, "#{self.class} must implement #display_outputs"
    end

    private

    def session_sets
      session.session_sets
    end

    def format_metric(value, precision: 3)
      return "—" if value.nil?

      value.round(precision)
    end
  end
end
