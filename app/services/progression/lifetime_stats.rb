module Progression
  class LifetimeStats
    def initialize(exercise: nil)
      @exercise = exercise
    end

    def total_reps
      session_sets.sum { |set| set.reps || 0 }
    end

    def total_volume
      session_sets.sum { |set| (set.reps || 0) * (set.effective_weight_kg || 0) }
    end

    def cumulative_reps_by_date
      cumulative_series { |set| set.reps || 0 }
    end

    def cumulative_volume_by_date
      cumulative_series { |set| (set.reps || 0) * (set.effective_weight_kg || 0) }
    end

    private

    attr_reader :exercise

    def session_sets
      scope = SessionSet.joins(:session).includes(session: :exercise)
      scope = scope.where(sessions: { exercise_id: exercise.id }) if exercise
      scope.order(sessions: { date: :asc })
    end

    def cumulative_series
      running_total = 0

      session_sets.each_with_object({}) do |set, series|
        running_total += yield(set)
        series[set.session.date] = running_total
      end
    end
  end
end
