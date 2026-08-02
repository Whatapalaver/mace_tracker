class StatsController < ApplicationController
  def show
    @exercises = Exercise.order(:name)
    @exercise = Exercise.find_by(id: params[:exercise_id])
    @period = params[:period].presence || "daily"
    @stats = Progression::LifetimeStats.new(exercise: @exercise, period: @period)
    @session_shapes = SessionShape.global_ordered

    return unless @exercise

    @shape = SessionShape.find_by(name: params[:shape], user_id: nil) if params[:shape].present?
    return unless @shape

    @signatures = distinct_signatures
    @structural_value = params[:structural_value].presence
    return unless @structural_value

    @weights = distinct_weights
    @weight = params[:weight].presence
    @output_labels = Progression::Calculator.output_labels_for(@shape.name)
    @output_label = params[:output].presence || @output_labels.first
    @benchmarks_only = ActiveModel::Type::Boolean.new.cast(params[:benchmarks_only])

    @series = Progression::SignatureSeries.new(
      exercise: @exercise, session_shape: @shape, structural_value: @structural_value,
      output_label: @output_label, weight: @weight, benchmarks_only: @benchmarks_only
    ).to_h
  end

  private

  def structural_columns
    Progression::ComparabilityKey.structural_columns_for(@shape.name)
  end

  def distinct_signatures
    rows = Session.where(exercise_id: @exercise.id, session_shape_id: @shape.id)
                   .distinct.pluck(*structural_columns)
    rows = rows.map { |row| structural_columns.size == 1 ? [ row ] : row }
    rows.reject { |row| row.any?(&:nil?) }.uniq.sort.map do |row|
      { value: row.join(":"), label: signature_label(row) }
    end
  end

  # Weight-agnostic by design — the signature groups sessions across weight changes, so its
  # label must not bake in one arbitrary session's weight (that's what the separate Weight
  # filter is for).
  def signature_label(row)
    case @shape.name
    when SessionShape::INTERVAL_WORK
      work_seconds, rest_seconds, sets_count = row
      Progression::IntervalFormula.render_without_weight_values(work_seconds: work_seconds, rest_seconds: rest_seconds,
                                                                  sets_count: sets_count)
    when SessionShape::FIXED_REPS_FOR_TIME
      "#{row.first} reps"
    when SessionShape::EMOM
      "#{row.first} reps/min"
    end
  end

  def decoded_structural_value
    Progression::ComparabilityKey.decode_structural_value(@shape.name, @structural_value)
  end

  def distinct_weights
    Session.where(exercise_id: @exercise.id, session_shape_id: @shape.id)
           .where(decoded_structural_value)
           .distinct.pluck(:weight_kg).compact.sort
  end
end
