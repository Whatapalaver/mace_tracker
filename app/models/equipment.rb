class Equipment < ApplicationRecord
  has_many :exercises

  validates :name, presence: true, uniqueness: { scope: :user_id }
end
