module Progression
  class IntervalWorkCalculator < BaseCalculator
    def self.output_labels
      [ "Best pace", "Avg pace", "Total output", "Output / total time", "Output / working time" ]
    end

    def pace_per_set
      session_sets.filter_map { |set| set_pace(set) }
    end

    def best_pace
      pace_per_set.max
    end

    def avg_pace
      paces = pace_per_set
      return nil if paces.empty?

      paces.sum / paces.size.to_f
    end

    def total_session_output
      total_volume
    end

    def output_per_total_time
      total = total_time_seconds
      return nil if total.nil? || total.zero?

      total_volume.to_f / total.to_f
    end

    def output_per_working_time
      total = working_time_seconds
      return nil if total.nil? || total.zero?

      total_volume.to_f / total.to_f
    end

    def outputs
      {
        "Best pace" => best_pace,
        "Avg pace" => avg_pace,
        "Total output" => total_session_output,
        "Output / total time" => output_per_total_time,
        "Output / working time" => output_per_working_time
      }
    end

    PACE_LABELS = [ "Best pace", "Avg pace" ].freeze

    private

    def precision_for(label)
      return 1 if PACE_LABELS.include?(label)

      label == "Total output" ? 0 : super
    end

    def unit_for(label)
      "reps/min" if PACE_LABELS.include?(label)
    end

    def set_pace(set)
      duration = set.effective_duration_seconds
      return nil if set.reps.nil? || duration.nil? || duration.zero?

      set.reps * 60.0 / duration
    end

    def total_time_seconds
      return nil if working_time_seconds.nil? || rest_time_seconds.nil?

      working_time_seconds + rest_time_seconds
    end

    def working_time_seconds
      sum_or_nil(session_sets.map(&:effective_duration_seconds))
    end

    def rest_time_seconds
      sum_or_nil(session_sets.map(&:effective_rest_seconds_actual))
    end

    def sum_or_nil(values)
      return nil if values.any?(&:nil?)

      values.sum
    end
  end
end
