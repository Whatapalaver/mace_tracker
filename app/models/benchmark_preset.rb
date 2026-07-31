class BenchmarkPreset < ApplicationRecord
  include ShapeConditionalFields

  belongs_to :exercise
  has_many :sessions

  validates :name, presence: true
end
