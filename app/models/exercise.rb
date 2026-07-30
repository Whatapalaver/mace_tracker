class Exercise < ApplicationRecord
  enum :arm, { single: 0, double: 1, n_a: 2 }, validate: true

  validates :name, presence: true, uniqueness: { scope: [ :arm, :user_id ] }
end
