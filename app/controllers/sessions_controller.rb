class SessionsController < ApplicationController
  include SessionShapeOptions
  include SessionsExplorer

  # Every field that only one shape's signature/reps_list actually populates — cleared for any
  # shape that doesn't own it when an edit switches shapes, so e.g. converting a sets_and_reps
  # session to interval_work doesn't leave a stale reps value sitting alongside the new
  # work_seconds/rest_seconds/sets_count.
  SHAPE_OWNED_FIELDS = {
    SessionShape::INTERVAL_WORK => %i[work_seconds rest_seconds sets_count],
    SessionShape::FIXED_REPS_FOR_TIME => %i[reps],
    SessionShape::SETS_AND_REPS => %i[reps],
    SessionShape::EMOM => %i[reps_per_minute]
  }.freeze

  before_action :set_session, only: [ :show, :edit, :update, :destroy, :row ]
  before_action :set_edit_form_options, only: [ :edit, :update ]

  def index
    build_sessions_explorer
  end

  def new
    @session = Session.new(date: Date.current)
    prefill_from_benchmark_preset
    @exercises = Exercise.order(:name)
    @advanced_session_shapes = advanced_session_shapes
    @benchmark_presets = BenchmarkPreset.order(:name)
  end

  # Three distinct kinds of POST land here:
  #   1. The legacy review step's confirm submission (session_sets_attributes present) — for
  #      fixed_reps_for_time/emom only, reachable only via #2 below.
  #   2. A first-time submission of the collapsed "different shape" formula field
  #      (fixed_reps_for_time/emom only) — parses and renders the review step.
  #   3. The primary one-step signature+reps_list submission (interval_work/sets_and_reps,
  #      inferred from the signature text) — saves immediately, no review step.
  # Order matters: the review step's hidden fields never resubmit :formula, so checking
  # confirming_sets? first is what tells #1 apart from a fresh #3 submission.
  def create
    @session = Session.new(session_params)

    if confirming_sets?
      save_and_redirect || render(:review, status: :unprocessable_content)
    elsif @session.formula.present?
      create_via_legacy_formula
    else
      create_via_signature
    end
  end

  def show
    @calculator = Progression::Calculator.for(@session)
  end

  def edit
  end

  def update
    target_shape = params.dig(:session, :session_shape_id).presence ? SessionShape.find(params[:session][:session_shape_id]) : @session.session_shape
    signature_attrs = Progression::SessionSignature.parse(params.dig(:session, :signature), target_shape.name)

    if persist_signature_and_sets!(target_shape: target_shape, signature_attrs: signature_attrs,
                                    reps_list_text: params.dig(:session, :reps_list))
      render partial: "row", locals: { session: @session }
    else
      render :edit, status: :unprocessable_content
    end
  rescue Progression::SessionSignature::ParseError, Progression::RepsList::ParseError => e
    @session.errors.add(:base, e.message)
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

  def set_edit_form_options
    @exercises = Exercise.order(:name)
    @session_shapes = session_shapes
  end

  def cleared_fields_for(shape_name)
    owned = SHAPE_OWNED_FIELDS.fetch(shape_name, [])
    (SHAPE_OWNED_FIELDS.values.flatten.uniq - owned).index_with { nil }
  end

  # The primary one-step flow: shape inferred from the signature text, no review step. Shared
  # save/rebuild logic with #update lives in persist_signature_and_sets!.
  def create_via_signature
    shape_name, signature_attrs = Progression::SessionSignature.parse_inferred(@session.signature)
    target_shape = SessionShape.find_or_create_by!(name: shape_name, user_id: nil)

    if persist_signature_and_sets!(target_shape: target_shape, signature_attrs: signature_attrs,
                                    reps_list_text: @session.reps_list)
      redirect_to @session, notice: "Session logged."
    else
      render_new_with_errors
    end
  rescue Progression::SessionSignature::ParseError => e
    @session.errors.add(:signature, e.message)
    render_new_with_errors
  rescue Progression::RepsList::ParseError => e
    @session.errors.add(:reps_list, e.message)
    render_new_with_errors
  end

  # Shared by #create_via_signature and #update: parses the reps list, cross-checks it against
  # an interval_work signature's implied set count, then transactionally assigns the resolved
  # shape/signature and rebuilds session_sets from scratch. Returns false (with errors added to
  # @session) instead of raising, so both callers can re-render their own template on failure.
  def persist_signature_and_sets!(target_shape:, signature_attrs:, reps_list_text:)
    reps_list = Progression::RepsList.parse(reps_list_text)

    if target_shape.name == SessionShape::INTERVAL_WORK && signature_attrs[:sets_count] != reps_list.size
      @session.errors.add(:base,
        "Signature implies #{signature_attrs[:sets_count]} sets but #{reps_list.size} rep values were given")
      return false
    end

    ActiveRecord::Base.transaction do
      @session.assign_attributes(session_shared_params.merge(cleared_fields_for(target_shape.name))
        .merge(signature_attrs).merge(session_shape_id: target_shape.id))
      @session.save!
      @session.session_sets.destroy_all
      reps_list.each_with_index do |entry, index|
        @session.session_sets.create!(set_number: index + 1, reps: entry.reps, weight_kg: entry.weight_kg)
      end
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    @session.errors.add(:base, e.record.errors.full_messages.to_sentence)
    false
  end

  def session_shared_params
    params.expect(session: [ :date, :exercise_id, :tool_id, :benchmark_preset_id, :weight_kg, :is_benchmark, :notes ])
  end

  def confirming_sets?
    session_params[:session_sets_attributes].present?
  end

  # The legacy two-step flow, reachable only through the log form's collapsed "different shape"
  # section (fixed_reps_for_time/emom — shapes the primary flow can't infer from bare text, and
  # which fixed_reps_for_time additionally needs a real review step for, to capture per-set
  # duration_seconds).
  def create_via_legacy_formula
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
  # (a coincidental match isn't necessarily an intentional benchmark attempt). Only reachable via
  # the legacy formula/review flow — the primary one-step flow has no review step to host this.
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
    @advanced_session_shapes = advanced_session_shapes
    @benchmark_presets = BenchmarkPreset.order(:name)
    # Reopen the collapsed "different shape" section when that's the path that failed, so the
    # error and what was typed stay visible instead of hiding behind a closed <details>.
    @advanced_shape_open = @session.formula.present?
    render :new, status: :unprocessable_content
  end

  # Populates either the primary Signature/Weight fields (interval_work/sets_and_reps presets)
  # or the collapsed section's legacy Formula field (fixed_reps_for_time/emom presets, which also
  # reopens that section so the prefilled value is visible).
  def prefill_from_benchmark_preset
    return if params[:benchmark_preset_id].blank?

    preset = BenchmarkPreset.find(params[:benchmark_preset_id])
    case preset.session_shape.name
    when SessionShape::INTERVAL_WORK, SessionShape::SETS_AND_REPS
      @session.assign_attributes(
        benchmark_preset_id: preset.id,
        exercise_id: preset.exercise_id,
        weight_kg: preset.weight_kg,
        signature: signature_for_preset(preset)
      )
    when SessionShape::FIXED_REPS_FOR_TIME, SessionShape::EMOM
      @session.assign_attributes(
        benchmark_preset_id: preset.id,
        exercise_id: preset.exercise_id,
        session_shape_id: preset.session_shape_id,
        formula: formula_for_preset(preset)
      )
      @advanced_shape_open = true
    end
  end

  def signature_for_preset(preset)
    case preset.session_shape.name
    when SessionShape::INTERVAL_WORK
      Progression::IntervalFormula.render_without_weight(preset)
    when SessionShape::SETS_AND_REPS
      preset.reps.to_s
    end
  end

  def formula_for_preset(preset)
    case preset.session_shape.name
    when SessionShape::FIXED_REPS_FOR_TIME
      Progression::RepsFormula.render(count: 1, reps: preset.reps, weight_kg: preset.weight_kg)
    when SessionShape::EMOM
      Progression::RepsFormula.render(count: 1, reps: preset.reps_per_minute, weight_kg: preset.weight_kg)
    end
  end

  def session_params
    params.expect(session: [ :date, :exercise_id, :tool_id, :session_shape_id, :benchmark_preset_id, :is_benchmark,
                             :formula, :signature, :reps_list, :weight_kg, :work_seconds, :rest_seconds,
                             :sets_count, :reps, :reps_per_minute, :notes,
                             session_sets_attributes: [ [ :set_number, :duration_seconds, :reps ] ] ])
  end
end
