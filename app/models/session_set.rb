class SessionSet < ApplicationRecord
  belongs_to :session

  validates :set_number, presence: true, uniqueness: { scope: :session_id },
                          numericality: { greater_than: 0, only_integer: true }
  validates :reps, :duration_seconds, :heart_rate_avg, :heart_rate_end,
            numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  # Zero rest is legitimate (e.g. a single-set all-out effort), unlike the other fields above.
  validates :rest_seconds_actual, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validates :weight_kg, numericality: { greater_than: 0 }, allow_nil: true

  def effective_weight_kg
    weight_kg || session.weight_kg
  end

  def effective_duration_seconds
    duration_seconds || session.work_seconds
  end

  def effective_rest_seconds_actual
    rest_seconds_actual || session.rest_seconds
  end
end
