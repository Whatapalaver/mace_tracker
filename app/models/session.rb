class Session < ApplicationRecord
  include ShapeConditionalFields

  belongs_to :exercise
  belongs_to :benchmark_preset, optional: true
  has_many :session_sets, dependent: :destroy
  accepts_nested_attributes_for :session_sets

  # Transient — carries the notation text (e.g. "5(5mw+5mr)@10kg") through the log form; never
  # persisted. Session's real weight_kg/work_seconds/rest_seconds/sets_count columns are what
  # get derived from it and saved.
  attr_accessor :formula

  validates :date, presence: true
  validates :rpe_session, numericality: { greater_than: 0 }, allow_nil: true

  before_validation :derive_is_benchmark

  # The one structural (non-weight) value defining this session's signature — e.g.
  # work_seconds for interval_work — used to deep-link into the stats page's
  # signature browser.
  def structural_value
    public_send(Progression::ComparabilityKey.structural_column_for(session_shape.name))
  end

  private

  def derive_is_benchmark
    self.is_benchmark = true if benchmark_preset_id.present?
  end
end
