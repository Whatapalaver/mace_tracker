class Session < ApplicationRecord
  include ShapeConditionalFields

  belongs_to :exercise
  belongs_to :benchmark_preset, optional: true
  belongs_to :tool, optional: true
  has_many :session_sets, dependent: :destroy
  accepts_nested_attributes_for :session_sets

  # Transient — carries the notation text (e.g. "5(5mw+5mr)@10kg") through the log form; never
  # persisted. Session's real weight_kg/work_seconds/rest_seconds/sets_count columns are what
  # get derived from it and saved.
  attr_accessor :formula

  validates :date, presence: true
  validates :rpe_session, numericality: { greater_than: 0 }, allow_nil: true
  validate :tool_matches_exercise_equipment

  before_validation :derive_is_benchmark

  # The structural (non-weight) value defining this session's signature — e.g.
  # "300:300:3" (work/rest/sets) for interval_work — used to deep-link into the stats page's
  # signature browser.
  def structural_value
    Progression::ComparabilityKey.encode_structural_value(self)
  end

  # The human-readable, weight-agnostic notation for this session's shape (e.g. "3(5mw+5mr)"
  # for interval_work, "108 reps" for fixed_reps_for_time) — used in the history table, where
  # weight is shown as its own column.
  def weight_agnostic_signature
    case session_shape.name
    when SessionShape::INTERVAL_WORK
      Progression::IntervalFormula.render_without_weight(self)
    when SessionShape::FIXED_REPS_FOR_TIME, SessionShape::SETS_AND_REPS
      "#{reps} reps"
    when SessionShape::EMOM
      "#{reps_per_minute} reps/min"
    end
  end

  # The editable form of the signature — unlike weight_agnostic_signature, always exactly what
  # Progression::SessionSignature.parse accepts back for this shape (a bare number for
  # fixed_reps_for_time/sets_and_reps/emom, with no "reps"/"reps/min" suffix), so pre-filling the
  # history table's inline-edit field with this round-trips instead of failing to parse.
  def signature_edit_value
    case session_shape.name
    when SessionShape::INTERVAL_WORK
      weight_agnostic_signature
    when SessionShape::FIXED_REPS_FOR_TIME, SessionShape::SETS_AND_REPS
      reps.to_s
    when SessionShape::EMOM
      reps_per_minute.to_s
    end
  end

  # The actual reps performed in each set, in order — e.g. "184, 181, 175".
  def reps_summary
    session_sets.order(:set_number).pluck(:reps).join(", ")
  end

  private

  def derive_is_benchmark
    self.is_benchmark = true if benchmark_preset_id.present?
  end

  def tool_matches_exercise_equipment
    return unless tool && exercise

    errors.add(:tool, "must be a piece of #{exercise.equipment.name} equipment") if tool.equipment_id != exercise.equipment_id
  end
end
