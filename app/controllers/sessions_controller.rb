class SessionsController < ApplicationController
  include SessionShapeOptions

  PER_PAGE = 50

  before_action :set_session, only: [ :show, :edit, :update, :destroy, :row ]
  before_action :set_exercises, only: [ :edit, :update ]

  def index
    # @years/@months only ever populate the filter dropdowns' options (so they only ever offer
    # choices with actual data) — the incoming params are validated separately and more loosely,
    # so that filtering down to a year/month with zero matching sessions still applies the filter
    # and shows an empty result, rather than being treated as "invalid" and silently ignored.
    @years = Session.distinct.pluck(:date).map(&:year).uniq.sort.reverse
    @year = params[:year].presence&.to_i

    @months = @year ? Session.where(date: Date.new(@year, 1, 1)..Date.new(@year, 12, 31))
                              .distinct.pluck(:date).map(&:month).uniq.sort : []
    @month = params[:month].presence&.to_i
    @month = nil unless @year && (1..12).cover?(@month)

    @equipment_list = Equipment.order(:name)
    @equipment_id = params[:equipment_id].presence
    @exercises = Exercise.order(:name)
    @exercises = @exercises.where(equipment_id: @equipment_id) if @equipment_id
    @exercise_id = params[:exercise_id].presence
    @exercise_id = nil if @exercise_id && !@exercises.exists?(id: @exercise_id)

    scope = Session.order(date: :desc, id: :desc)
    scope = scope.where(date: Date.new(@year, 1, 1)..Date.new(@year, 12, 31)) if @year
    scope = scope.where(date: Date.new(@year, @month, 1)..Date.new(@year, @month, -1)) if @year && @month
    scope = scope.where(exercise_id: @exercise_id) if @exercise_id
    scope = scope.joins(:exercise).where(exercise: { equipment_id: @equipment_id }) if @equipment_id && !@exercise_id

    @total_count = scope.count
    @total_pages = [ (@total_count / PER_PAGE.to_f).ceil, 1 ].max
    @page = [ [ params[:page].to_i, 1 ].max, @total_pages ].min
    @sessions = scope.includes(:exercise, :session_shape, :session_sets).offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end

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
    @calculator = Progression::Calculator.for(@session)
  end

  def edit
  end

  def update
    reps_list = parse_reps_list(params.dig(:session, :reps_list))
    signature_attrs = Progression::SessionSignature.parse(params.dig(:session, :signature), @session.session_shape.name)

    if @session.session_shape.name == SessionShape::INTERVAL_WORK && signature_attrs[:sets_count] != reps_list.size
      @session.errors.add(:base,
        "Signature implies #{signature_attrs[:sets_count]} sets but #{reps_list.size} rep values were given")
      return render :edit, status: :unprocessable_content
    end

    ActiveRecord::Base.transaction do
      @session.assign_attributes(session_edit_params.merge(signature_attrs))
      @session.save!
      @session.session_sets.destroy_all
      reps_list.each_with_index { |reps, index| @session.session_sets.create!(set_number: index + 1, reps: reps) }
    end

    render partial: "row", locals: { session: @session }
  rescue Progression::SessionSignature::ParseError => e
    @session.errors.add(:base, e.message)
    render :edit, status: :unprocessable_content
  rescue ActiveRecord::RecordInvalid => e
    @session.errors.add(:base, e.record.errors.full_messages.to_sentence)
    render :edit, status: :unprocessable_content
  end

  def row
    render partial: "row", locals: { session: @session }
  end

  def destroy
    @session.destroy
    redirect_to sessions_path, notice: "Session deleted."
  end

  private

  def set_session
    @session = Session.find(params[:id])
  end

  def set_exercises
    @exercises = Exercise.order(:name)
  end

  def parse_reps_list(text)
    values = text.to_s.split(",").map(&:strip).reject(&:empty?)
    raise Progression::SessionSignature::ParseError, "At least one rep value is required" if values.empty?

    values.map { |value| Integer(value) }
  rescue ArgumentError
    raise Progression::SessionSignature::ParseError, "Reps must be a comma-separated list of whole numbers"
  end

  def session_edit_params
    params.expect(session: [ :date, :exercise_id, :weight_kg, :is_benchmark, :notes ])
  end

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
    when SessionShape::FIXED_REPS_FOR_TIME, SessionShape::SETS_AND_REPS
      @session.weight_kg = result.weight_kg
      @session.reps = result.reps
      result.count.times { |index| @session.session_sets.build(set_number: index + 1, reps: result.reps) }
    when SessionShape::EMOM
      @session.weight_kg = result.weight_kg
      @session.reps_per_minute = result.reps
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
    when SessionShape::FIXED_REPS_FOR_TIME, SessionShape::SETS_AND_REPS
      scope = scope.where(reps: @session.reps)
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
    when SessionShape::FIXED_REPS_FOR_TIME, SessionShape::SETS_AND_REPS
      Progression::RepsFormula.render(count: 1, reps: preset.reps, weight_kg: preset.weight_kg)
    when SessionShape::EMOM
      Progression::RepsFormula.render(count: 1, reps: preset.reps_per_minute, weight_kg: preset.weight_kg)
    end
  end

  def session_params
    params.expect(session: [ :date, :exercise_id, :session_shape_id, :benchmark_preset_id, :is_benchmark,
                             :formula, :weight_kg, :work_seconds, :rest_seconds,
                             :sets_count, :reps, :reps_per_minute, :notes,
                             session_sets_attributes: [ [ :set_number, :duration_seconds, :reps ] ] ])
  end
end
