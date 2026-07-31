module Progression
  class FixedRepsForTimeCalculator < BaseCalculator
    def times
      session_sets.filter_map(&:duration_seconds)
    end

    def best_time
      times.min
    end

    def avg_time
      return nil if times.empty?

      times.sum / times.size.to_f
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

    def outputs
      {
        "Best time" => best_time,
        "Avg time" => avg_time,
        "Best pace" => best_pace,
        "Avg pace" => avg_pace
      }
    end

    private

    def precision_for(label)
      label.include?("time") ? 0 : super
    end

    def set_pace(set)
      return nil if set.reps.nil? || set.duration_seconds.nil? || set.duration_seconds.zero?

      set.reps / set.duration_seconds.to_f
    end
  end
end
