class SessionsController < ApplicationController
  include SessionShapeOptions

  def new
    @session = Session.new(date: Date.current)
    prefill_from_benchmark_preset
    @exercises = Exercise.order(:name)
    @session_shapes = session_shapes
  end

  def create
    @session = Session.new(session_params)

    if @session.save
      redirect_to @session, notice: "Session logged."
    else
      @exercises = Exercise.order(:name)
      @session_shapes = session_shapes
      render :new, status: :unprocessable_content
    end
  end

  def show
    @session = Session.find(params[:id])
    @calculator = Progression::Calculator.for(@session)
    @benchmarks_only = ActiveModel::Type::Boolean.new.cast(params[:benchmarks_only])
    @pace_series = pace_series
  end

  private

  def pace_series
    return nil unless interval_work?

    Progression::IntervalWorkPaceSeries.new(@session, benchmarks_only: @benchmarks_only).to_h
  end

  def interval_work?
    @session.session_shape.name == SessionShape::INTERVAL_WORK
  end

  def prefill_from_benchmark_preset
    return if params[:benchmark_preset_id].blank?

    preset = BenchmarkPreset.find(params[:benchmark_preset_id])
    @session.assign_attributes(
      benchmark_preset_id: preset.id,
      exercise_id: preset.exercise_id,
      session_shape_id: preset.session_shape_id,
      planned_weight_kg: preset.planned_weight_kg,
      planned_work_seconds: preset.planned_work_seconds,
      planned_rest_seconds: preset.planned_rest_seconds,
      planned_sets: preset.planned_sets,
      target_reps: preset.target_reps,
      target_reps_per_minute: preset.target_reps_per_minute
    )
  end

  def session_params
    params.expect(session: [ :date, :exercise_id, :session_shape_id, :benchmark_preset_id, :is_benchmark,
                             :planned_weight_kg, :planned_work_seconds, :planned_rest_seconds, :planned_sets,
                             :target_reps, :target_reps_per_minute, :notes ])
  end
end
