class StatsController < ApplicationController
  def show
    @equipment_list = Equipment.order(:name)

    # A fresh, filterless visit (e.g. the "Stats" nav link) defaults to Mace 10-2 rather than
    # showing an empty page — every other entry point (the filter forms themselves) always
    # submits equipment_id/exercise_id explicitly, even when blank, so checking the params key
    # (not just presence) distinguishes "never chosen yet" from "explicitly cleared".
    fresh_visit = !params.key?(:equipment_id) && !params.key?(:exercise_id)
    default_exercise = Exercise.joins(:equipment).find_by(equipment: { name: "Mace" }, name: "10-2") if fresh_visit

    @equipment_id = params[:equipment_id].presence || default_exercise&.equipment_id&.to_s
    @exercises = Exercise.order(:name)
    @exercises = @exercises.where(equipment_id: @equipment_id) if @equipment_id
    @exercise = Exercise.find_by(id: params[:exercise_id]) || default_exercise
    @exercise = nil if @exercise && @equipment_id.present? && @exercise.equipment_id.to_s != @equipment_id
    @period = params[:period].presence || "daily"
    @stats = Progression::LifetimeStats.new(exercise: @exercise, exercise_ids: @equipment_id && @exercises.ids,
                                             period: @period)
    @personal_bests = @exercise ? @stats.personal_bests : []
    @session_shapes = SessionShape.global_ordered

    return unless @exercise

    if params.key?(:shape)
      @shape = SessionShape.find_by(name: params[:shape], user_id: nil) if params[:shape].present?
    else
      # A fresh exercise selection (shape not chosen or cleared yet) defaults to the first shape
      # that actually has sessions logged for this exercise — @session_shapes.find returns nil,
      # not an error, when none do, so @shape stays nil and the guard below stops there safely.
      @shape = @session_shapes.find { |shape| Session.exists?(exercise_id: @exercise.id, session_shape_id: shape.id) }
    end
    return unless @shape

    # Granularity only means anything for interval_work — the other shapes have no wrapping
    # "N(...)" structure to optionally ignore, so segment and full are identical for them.
    @granularity = params[:granularity].presence || "full"
    @granularity = "full" unless @shape.name == SessionShape::INTERVAL_WORK

    @signatures = distinct_signatures
    @structural_value = params.key?(:structural_value) ? params[:structural_value].presence : @signatures.first&.fetch(:value)
    @structural_value = nil unless @signatures.any? { |signature| signature[:value] == @structural_value }
    return unless @structural_value

    @weights = distinct_weights
    @weight = params[:weight].presence
    @output_labels = output_labels
    @output_label = params[:output].presence
    @output_label = @output_labels.first unless @output_labels.include?(@output_label)
    @benchmarks_only = ActiveModel::Type::Boolean.new.cast(params[:benchmarks_only])

    @series = Progression::SignatureSeries.new(
      exercise: @exercise, session_shape: @shape, structural_value: @structural_value, granularity: @granularity,
      output_label: @output_label, weight: @weight, benchmarks_only: @benchmarks_only
    ).to_h
  end

  private

  def structural_columns
    Progression::ComparabilityKey.structural_columns_for(@shape.name, granularity: @granularity)
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
      if @granularity == "segment"
        Progression::IntervalFormula.render_without_weight_values(work_seconds: row.first, rest_seconds: 0, sets_count: 1)
      else
        work_seconds, rest_seconds, sets_count = row
        Progression::IntervalFormula.render_without_weight_values(work_seconds: work_seconds, rest_seconds: rest_seconds,
                                                                    sets_count: sets_count)
      end
    when SessionShape::FIXED_REPS_FOR_TIME, SessionShape::SETS_AND_REPS
      "#{row.first} reps"
    when SessionShape::EMOM
      "#{row.first} reps/min"
    end
  end

  def decoded_structural_value
    Progression::ComparabilityKey.decode_structural_value(@shape.name, @structural_value, granularity: @granularity)
  end

  def distinct_weights
    Session.where(exercise_id: @exercise.id, session_shape_id: @shape.id)
           .where(decoded_structural_value)
           .distinct.pluck(:weight_kg).compact.sort
  end

  # Total output / output-per-time only mean something when every matching session shares the
  # same rest and set-count structure — under segment granularity that's no longer guaranteed
  # (a single 5-minute set and three 5-minute sets with rest both count), so only the rate-based
  # pace outputs, which already collapse to one value per session regardless of set count, stay
  # available.
  def output_labels
    labels = Progression::Calculator.output_labels_for(@shape.name)
    return labels unless @shape.name == SessionShape::INTERVAL_WORK && @granularity == "segment"

    labels & [ "Best pace", "Avg pace" ]
  end
end
