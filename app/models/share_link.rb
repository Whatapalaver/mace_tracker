class ShareLink < ApplicationRecord
  has_secure_token :token

  validates :token, presence: true, uniqueness: true

  def expired?
    expires_at.present? && expires_at.past?
  end

  def exercise
    Exercise.find_by(id: scope["exercise_id"]) if scope["exercise_id"].present?
  end

  def sessions
    exercise ? Session.where(exercise_id: exercise.id) : Session.all
  end

  def description
    exercise ? "#{exercise.display_name} only" : "All exercises"
  end
end
