class Session < ApplicationRecord
  include ShapeConditionalPlannedFields

  belongs_to :exercise
  belongs_to :benchmark_preset, optional: true
  has_many :session_sets, dependent: :destroy

  validates :date, presence: true
  validates :rpe_session, numericality: { greater_than: 0 }, allow_nil: true

  before_validation :derive_is_benchmark

  private

  def derive_is_benchmark
    self.is_benchmark = true if benchmark_preset_id.present?
  end
end
