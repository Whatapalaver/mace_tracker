class BenchmarkPreset < ApplicationRecord
  include ShapeConditionalPlannedFields

  belongs_to :exercise
  has_many :sessions

  validates :name, presence: true
end
