module SessionShapeOptions
  extend ActiveSupport::Concern

  private

  def session_shapes
    SessionShape::ORDERED_NAMES.each { |name| SessionShape.find_or_create_by!(name: name, user_id: nil) }
    SessionShape.global_ordered
  end

  # The two shapes the primary log form can't infer from bare signature text (their notation is
  # textually identical to sets_and_reps's) — offered only through the form's collapsed "different
  # shape" section, which still uses the legacy formula/review flow.
  ADVANCED_SHAPE_NAMES = [ SessionShape::FIXED_REPS_FOR_TIME, SessionShape::EMOM ].freeze

  def advanced_session_shapes
    session_shapes.select { |shape| ADVANCED_SHAPE_NAMES.include?(shape.name) }
  end
end
