module ShapeConditionalFields
  extend ActiveSupport::Concern

  included do
    belongs_to :session_shape

    validates :weight_kg, numericality: { greater_than: 0 }, allow_nil: true
    validates :work_seconds, :sets_count, :reps, :reps_per_minute,
              numericality: { greater_than: 0, only_integer: true }, allow_nil: true
    # Zero rest is legitimate (e.g. a single-set all-out effort), unlike the other fields above.
    validates :rest_seconds, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true

    with_options if: -> { session_shape&.name == SessionShape::INTERVAL_WORK } do
      validates :weight_kg, :work_seconds, :rest_seconds, :sets_count, presence: true
    end

    with_options if: -> { [ SessionShape::FIXED_REPS_FOR_TIME, SessionShape::SETS_AND_REPS ].include?(session_shape&.name) } do
      validates :weight_kg, :reps, presence: true
    end

    with_options if: -> { session_shape&.name == SessionShape::EMOM } do
      validates :weight_kg, :reps_per_minute, presence: true
    end
  end
end
