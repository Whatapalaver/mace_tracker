class SessionsController < ApplicationController
  include SessionShapeOptions

  def new
    @session = Session.new(date: Date.current)
    prefill_from_benchmark_preset
    @exercises = Exercise.order(:name)
    @session_shapes = session_shapes
    @benchmark_presets = BenchmarkPreset.order(:name)
  end

  def create
    @session = Session.new(session_params)

    if confirming_sets?
      save_and_redirect || render(:review, status: :unprocessable_content)
    else
      parse_formula_then_respond
    end
  end

  def show
    @session = Session.find(params[:id])
    @calculator = Progression::Calculator.for(@session)
  end

  def destroy
    Session.find(params[:id]).destroy
    redirect_to session_sets_path, notice: "Session deleted."
  end

  private

  def confirming_sets?
    session_params[:session_sets_attributes].present?
  end

  def parse_formula_then_respond
    result = Progression::SessionFormula.parse(@session.formula, @session.session_shape.name)
    apply_parsed_result(result)

    if @session.session_shape.name == SessionShape::EMOM
      save_and_redirect || render_new_with_errors
    else
      @matching_preset = matching_benchmark_preset
      render :review
    end
  rescue Progression::SessionFormula::ParseError => e
    @session.errors.add(:formula, e.message)
    render_new_with_errors
  end

  def apply_parsed_result(result)
    case @session.session_shape.name
    when SessionShape::INTERVAL_WORK
      @session.assign_attributes(
        weight_kg: result.weight_kg,
        work_seconds: result.work_seconds,
        rest_seconds: result.rest_seconds,
        sets_count: result.sets_count
      )
      result.work_segments.each_with_index do |segment, index|
        @session.session_sets.build(set_number: index + 1, duration_seconds: segment[:duration_seconds])
      end
    when SessionShape::FIXED_REPS_FOR_TIME
      @session.weight_kg = result.weight_kg
      @session.target_reps = result.reps
      result.count.times { |index| @session.session_sets.build(set_number: index + 1, reps: result.reps) }
    when SessionShape::EMOM
      @session.weight_kg = result.weight_kg
      @session.target_reps_per_minute = result.reps
      result.count.times { |index| @session.session_sets.build(set_number: index + 1, reps: result.reps) }
    end
  end

  # Suggests attaching a preset when the parsed formula happens to numerically match one for
  # this exercise+shape — surfaced as an opt-in checkbox on the review step, never auto-attached
  # (a coincidental match isn't necessarily an intentional benchmark attempt).
  def matching_benchmark_preset
    scope = BenchmarkPreset.where(exercise_id: @session.exercise_id, session_shape_id: @session.session_shape_id,
                                   weight_kg: @session.weight_kg)
    case @session.session_shape.name
    when SessionShape::INTERVAL_WORK
      scope = scope.where(work_seconds: @session.work_seconds,
                           rest_seconds: @session.rest_seconds,
                           sets_count: @session.sets_count)
    when SessionShape::FIXED_REPS_FOR_TIME
      scope = scope.where(target_reps: @session.target_reps)
    end
    scope.first
  end

  def save_and_redirect
    return false unless @session.save

    redirect_to @session, notice: "Session logged."
    true
  end

  def render_new_with_errors
    @exercises = Exercise.order(:name)
    @session_shapes = session_shapes
    @benchmark_presets = BenchmarkPreset.order(:name)
    render :new, status: :unprocessable_content
  end

  def prefill_from_benchmark_preset
    return if params[:benchmark_preset_id].blank?

    preset = BenchmarkPreset.find(params[:benchmark_preset_id])
    @session.assign_attributes(
      benchmark_preset_id: preset.id,
      exercise_id: preset.exercise_id,
      session_shape_id: preset.session_shape_id,
      formula: formula_for_preset(preset)
    )
  end

  def formula_for_preset(preset)
    case preset.session_shape.name
    when SessionShape::INTERVAL_WORK
      Progression::IntervalFormula.render(preset)
    when SessionShape::FIXED_REPS_FOR_TIME
      Progression::RepsFormula.render(count: 1, reps: preset.target_reps, weight_kg: preset.weight_kg)
    when SessionShape::EMOM
      Progression::RepsFormula.render(count: 1, reps: preset.target_reps_per_minute, weight_kg: preset.weight_kg)
    end
  end

  def session_params
    params.expect(session: [ :date, :exercise_id, :session_shape_id, :benchmark_preset_id, :is_benchmark,
                             :formula, :weight_kg, :work_seconds, :rest_seconds,
                             :sets_count, :target_reps, :target_reps_per_minute, :notes,
                             session_sets_attributes: [ [ :set_number, :duration_seconds, :reps ] ] ])
  end
end
