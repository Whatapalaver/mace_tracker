module Progression
  # For sessions with no timing at all — straight sets x reps at a weight (e.g. 4 sets of 24
  # reps @ 10kg). No pace/time outputs exist since nothing is timed; only totals matter.
  class SetsAndRepsCalculator < BaseCalculator
    def self.output_labels
      [ "Total reps", "Total output" ]
    end

    def total_reps
      session_sets.sum { |set| set.reps || 0 }
    end

    def total_output
      total_volume
    end

    def outputs
      {
        "Total reps" => total_reps,
        "Total output" => total_output
      }
    end

    private

    def precision_for(_label)
      0
    end
  end
end
