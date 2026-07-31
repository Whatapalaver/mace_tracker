module Progression
  # Chart-ready {series_label => {date => value}} data for a chosen output across every session
  # matching a structural signature (exercise + shape + the shape's one structural key column),
  # replacing the interval_work-only Progression::IntervalWorkPaceSeries. Weight is off by
  # default (each distinct weight becomes its own series, e.g. "8kg"/"10kg", so a weight change
  # over time stays visible); passing weight: locks to a single series for that weight.
  class SignatureSeries
    def initialize(exercise:, session_shape:, structural_value:, output_label:, weight: nil, benchmarks_only: false)
      @exercise = exercise
      @session_shape = session_shape
      @structural_value = structural_value
      @output_label = output_label
      @weight = weight.presence
      @benchmarks_only = benchmarks_only
    end

    def to_h
      sessions = matching_sessions
      sessions = sessions.select { |session| session.planned_weight_kg.to_f == @weight.to_f } if @weight

      sessions.group_by { |session| "#{session.planned_weight_kg}kg" }.transform_values do |group|
        group.each_with_object({}) do |session, series|
          value = Calculator.for(session).outputs[@output_label]
          series[session.date] = value if value
        end
      end
    end

    private

    def matching_sessions
      column = ComparabilityKey.structural_column_for(@session_shape.name)
      scope = Session.where(exercise_id: @exercise.id, session_shape_id: @session_shape.id, column => @structural_value)
      scope = scope.where(is_benchmark: true) if @benchmarks_only
      scope.includes(:session_sets).order(:date).to_a
    end
  end
end
