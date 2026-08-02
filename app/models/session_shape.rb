class SessionShape < ApplicationRecord
  INTERVAL_WORK = "interval_work"
  FIXED_REPS_FOR_TIME = "fixed_reps_for_time"
  EMOM = "emom"
  SETS_AND_REPS = "sets_and_reps"

  ORDERED_NAMES = [ INTERVAL_WORK, FIXED_REPS_FOR_TIME, EMOM, SETS_AND_REPS ].freeze

  LABELS = {
    INTERVAL_WORK => "Interval work",
    FIXED_REPS_FOR_TIME => "Fixed reps for time",
    EMOM => "EMOM",
    SETS_AND_REPS => "Sets & reps"
  }.freeze

  has_many :sessions

  validates :name, presence: true, uniqueness: { scope: :user_id }

  def self.global_ordered
    where(user_id: nil).to_a.sort_by { |shape| ORDERED_NAMES.index(shape.name) || ORDERED_NAMES.size }
  end

  def label
    LABELS.fetch(name, name.humanize)
  end
end
