module Progression
  class EmomCalculator < BaseCalculator
    def self.output_labels
      [ "Sets completed" ]
    end

    def total_sets_completed
      session_sets.count
    end

    def outputs
      { "Sets completed" => total_sets_completed }
    end
  end
end
