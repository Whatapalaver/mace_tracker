module Progression
  class FixedRepsForTimeCalculator < BaseCalculator
    def time_seconds
      primary_set&.duration_seconds
    end

    def pace
      set = primary_set
      return nil if set.nil? || set.reps.nil? || set.duration_seconds.nil? || set.duration_seconds.zero?

      set.reps / set.duration_seconds.to_f
    end

    def display_outputs
      {
        "Time (sec)" => format_metric(time_seconds, precision: 0),
        "Pace" => format_metric(pace)
      }
    end

    private

    def primary_set
      session_sets.order(:set_number).first
    end
  end
end
