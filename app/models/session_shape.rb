class SessionShape < ApplicationRecord
  validates :name, presence: true, uniqueness: { scope: :user_id }
end
