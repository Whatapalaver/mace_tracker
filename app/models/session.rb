class Session < ApplicationRecord
  belongs_to :exercise
  belongs_to :session_shape
  has_many :session_sets, dependent: :destroy

  validates :date, presence: true

  validates :planned_weight_kg, :rpe_session, numericality: { greater_than: 0 }, allow_nil: true
  validates :planned_work_seconds, :planned_rest_seconds, :planned_sets,
            :target_reps, :target_reps_per_minute,
            numericality: { greater_than: 0, only_integer: true }, allow_nil: true

  with_options if: -> { session_shape&.name == SessionShape::INTERVAL_WORK } do
    validates :planned_weight_kg, :planned_work_seconds, :planned_rest_seconds, :planned_sets, presence: true
  end

  with_options if: -> { session_shape&.name == SessionShape::FIXED_REPS_FOR_TIME } do
    validates :planned_weight_kg, :target_reps, presence: true
  end

  with_options if: -> { session_shape&.name == SessionShape::EMOM } do
    validates :planned_weight_kg, :target_reps_per_minute, presence: true
  end
end
