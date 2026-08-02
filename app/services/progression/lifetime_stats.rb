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
      totals = session_sets.each_with_object(Hash.new(0)) do |set, hash|
        hash[period_key(set.session.date)] += yield(set)
      end
      fill_gaps(totals)
    end

    # Chartkick's column charts plot a plain category axis — whatever keys are present, evenly
    # spaced, with no notion of the calendar distance between them. Without this, a month with
    # no sessions just doesn't appear, so neighboring bars sit flush together instead of leaving
    # a visible gap. Filling every period in the range with 0 makes empty periods render as
    # actual empty columns, turning the axis into a true (if manually stepped) timeline.
    def fill_gaps(totals)
      return totals if totals.empty?

      keys = totals.keys.sort
      filled = {}
      current = keys.first
      while current <= keys.last
        filled[current] = totals[current] || 0
        current = next_period(current)
      end
      filled
    end

    def next_period(date)
      case period
      when "weekly" then date + 7.days
      when "monthly" then date.next_month
      when "yearly" then date.next_year
      else date + 1.day
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
