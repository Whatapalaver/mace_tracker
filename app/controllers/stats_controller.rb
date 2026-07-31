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

  def signature_label(value)
    representative = Session.where(exercise_id: @exercise.id, session_shape_id: @shape.id,
                                    structural_column => value).first
    case @shape.name
    when SessionShape::INTERVAL_WORK
      Progression::IntervalFormula.render(representative)
    when SessionShape::FIXED_REPS_FOR_TIME
      Progression::RepsFormula.render(count: 1, reps: representative.target_reps,
                                       weight_kg: representative.planned_weight_kg)
    when SessionShape::EMOM
      Progression::RepsFormula.render(count: 1, reps: representative.target_reps_per_minute,
                                       weight_kg: representative.planned_weight_kg)
    end
  end

  def distinct_weights
    Session.where(exercise_id: @exercise.id, session_shape_id: @shape.id, structural_column => @structural_value)
           .distinct.pluck(:planned_weight_kg).compact.sort
  end
end
