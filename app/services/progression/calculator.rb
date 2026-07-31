module Progression
  class Calculator
    class UnknownShapeError < StandardError; end

    REGISTRY = {
      SessionShape::INTERVAL_WORK => IntervalWorkCalculator,
      SessionShape::FIXED_REPS_FOR_TIME => FixedRepsForTimeCalculator,
      SessionShape::EMOM => EmomCalculator
    }.freeze

    def self.for(session)
      class_for(session.session_shape.name).new(session)
    end

    def self.output_labels_for(shape_name)
      class_for(shape_name).output_labels
    end

    def self.class_for(shape_name)
      REGISTRY.fetch(shape_name) do
        raise UnknownShapeError, "No calculator registered for session shape #{shape_name.inspect}"
      end
    end
  end
end
