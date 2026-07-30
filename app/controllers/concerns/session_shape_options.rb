module SessionShapeOptions
  extend ActiveSupport::Concern

  private

  def session_shapes
    SessionShape::ORDERED_NAMES.each { |name| SessionShape.find_or_create_by!(name: name, user_id: nil) }
    SessionShape.global_ordered
  end
end
