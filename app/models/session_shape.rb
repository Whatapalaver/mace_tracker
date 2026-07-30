class SessionShape < ApplicationRecord
  INTERVAL_WORK = "interval_work"
  FIXED_REPS_FOR_TIME = "fixed_reps_for_time"
  EMOM = "emom"

  has_many :sessions

  validates :name, presence: true, uniqueness: { scope: :user_id }
end
