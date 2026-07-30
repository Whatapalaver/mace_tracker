class SessionSet < ApplicationRecord
  belongs_to :session

  validates :set_number, presence: true, uniqueness: { scope: :session_id },
                          numericality: { greater_than: 0, only_integer: true }
  validates :reps, :duration_seconds, :rest_seconds_actual, :heart_rate_avg, :heart_rate_end,
            numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :weight_kg, numericality: { greater_than: 0 }, allow_nil: true

  def effective_weight_kg
    weight_kg || session.planned_weight_kg
  end
end
