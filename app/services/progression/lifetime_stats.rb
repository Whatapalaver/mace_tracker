module Progression
  class LifetimeStats
    PERIODS = %w[daily weekly monthly yearly].freeze

    def initialize(exercise: nil, exercise_ids: nil, period: "daily")
      @exercise = exercise
      @exercise_ids = exercise_ids
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

    # One series per weight — {"10kg" => {period => max_reps}} — so a chart can plot how the
    # heaviest weight's max reps-per-set trends separately from a lighter weight's, rather than
    # blending every weight into one misleading line. Unlike reps_by_period/volume_by_period,
    # periods with no set at that weight are left out entirely rather than zero-filled — a 0
    # here would misread as "did zero reps that day" instead of "didn't lift this weight that
    # day," so the line should skip the gap, not dip to the floor.
    def max_reps_by_weight_and_period
      by_weight.transform_keys { |weight| "#{weight}kg" }.transform_values do |sets|
        sets.each_with_object({}) do |set, totals|
          key = period_key(set.session.date)
          totals[key] = [ totals[key] || 0, set.reps || 0 ].max
        end
      end
    end

    # The heaviest single-set rep count ever logged at each weight, and when it happened — always
    # all-time regardless of the period toggle above, since a personal best isn't bucketed.
    def personal_bests
      by_weight.map do |weight, sets|
        best = sets.max_by { |set| set.reps || 0 }
        { weight: weight, date: best.session.date, reps: best.reps }
      end
    end

    private

    attr_reader :exercise, :exercise_ids, :period

    def session_sets
      scope = SessionSet.joins(:session).includes(session: :exercise)
      if exercise
        scope = scope.where(sessions: { exercise_id: exercise.id })
      elsif exercise_ids
        scope = scope.where(sessions: { exercise_id: exercise_ids })
      end
      scope.order(sessions: { date: :asc })
    end

    # Groups by effective weight, dropping sets with no known weight (can't be plotted or
    # compared per-weight) and sorting lightest-first.
    def by_weight
      session_sets.to_a.group_by(&:effective_weight_kg).reject { |weight, _| weight.nil? }.sort_by(&:first).to_h
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
