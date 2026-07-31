class StatsController < ApplicationController
  def show
    @exercises = Exercise.order(:name)
    @exercise = Exercise.find_by(id: params[:exercise_id])
    @stats = Progression::LifetimeStats.new(exercise: @exercise)
    @session_shapes = SessionShape.global_ordered

    return unless @exercise

    @shape = SessionShape.find_by(name: params[:shape], user_id: nil) if params[:shape].present?
    return unless @shape

    @signatures = distinct_signatures
    @structural_value = params[:structural_value].presence&.to_i
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

  def structural_column
    Progression::ComparabilityKey.structural_column_for(@shape.name)
  end

  def distinct_signatures
    values = Session.where(exercise_id: @exercise.id, session_shape_id: @shape.id)
                     .distinct.pluck(structural_column).compact.sort
    values.map { |value| { value: value, label: signature_label(value) } }
  end

  # Weight-agnostic by design — the signature groups sessions across weight changes, so its
  # label must not bake in one arbitrary session's weight (that's what the separate Weight
  # filter is for).
  def signature_label(value)
    case @shape.name
    when SessionShape::INTERVAL_WORK
      representative = Session.where(exercise_id: @exercise.id, session_shape_id: @shape.id,
                                      structural_column => value).first
      Progression::IntervalFormula.render_without_weight(representative)
    when SessionShape::FIXED_REPS_FOR_TIME
      "#{value} reps"
    when SessionShape::EMOM
      "#{value} reps/min"
    end
  end

  def distinct_weights
    Session.where(exercise_id: @exercise.id, session_shape_id: @shape.id, structural_column => @structural_value)
           .distinct.pluck(:weight_kg).compact.sort
  end
end
