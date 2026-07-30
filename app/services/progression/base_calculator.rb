module Progression
  class BaseCalculator
    attr_reader :session

    def initialize(session)
      @session = session
    end

    def total_volume
      session_sets.sum { |set| (set.reps || 0) * (set.effective_weight_kg || 0) }
    end

    private

    def session_sets
      session.session_sets
    end
  end
end
