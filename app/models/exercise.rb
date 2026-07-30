class Exercise < ApplicationRecord
  enum :arm, { single: 0, double: 1, n_a: 2 }, validate: true

  validates :name, presence: true, uniqueness: { scope: [ :arm, :user_id ] }

  ARM_LABELS = { "single" => "Single arm", "double" => "Double arm", "n_a" => "N/A" }.freeze

  def self.arm_options
    arms.keys.map { |key| [ ARM_LABELS.fetch(key), key ] }
  end

  def arm_label
    ARM_LABELS.fetch(arm)
  end
end
