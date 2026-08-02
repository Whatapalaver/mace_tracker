module Progression
  class LifetimeStats
    PERIODS = %w[daily weekly monthly yearly].freeze

    def initialize(exercise: nil, period: "daily")
      @exercise = exercise
      @period = PERIODS.include?(period) ? period : "daily"
    end

    def total_reps
      session_sets.sum { |set| set.reps || 0 }
    end

    def total_volume
      session_sets.sum { |set| (set.reps || 0) * (set.effective_weight_kg || 0) }
    end

    def reps_by_period
      totals_by_period { |set| set.reps || 0 }
    end

    def volume_by_period
      totals_by_period { |set| (set.reps || 0) * (set.effective_weight_kg || 0) }
    end

    private

    attr_reader :exercise, :period

    def session_sets
      scope = SessionSet.joins(:session).includes(session: :exercise)
      scope = scope.where(sessions: { exercise_id: exercise.id }) if exercise
      scope.order(sessions: { date: :asc })
    end

    def totals_by_period
      session_sets.each_with_object(Hash.new(0)) do |set, totals|
        totals[period_key(set.session.date)] += yield(set)
      end
    end

    def period_key(date)
      case period
      when "weekly" then date.beginning_of_week
      when "monthly" then date.beginning_of_month
      when "yearly" then date.beginning_of_year
      else date
      end
    end
  end
end
