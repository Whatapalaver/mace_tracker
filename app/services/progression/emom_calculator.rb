module Progression
  class EmomCalculator < BaseCalculator
    def total_sets_completed
      session_sets.count
    end

    def display_outputs
      { "Sets completed" => total_sets_completed }
    end
  end
end
