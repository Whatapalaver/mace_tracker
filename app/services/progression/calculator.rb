module Progression
  class Calculator
    class UnknownShapeError < StandardError; end

    REGISTRY = {
      SessionShape::INTERVAL_WORK => IntervalWorkCalculator,
      SessionShape::FIXED_REPS_FOR_TIME => FixedRepsForTimeCalculator,
      SessionShape::EMOM => EmomCalculator
    }.freeze

    def self.for(session)
      calculator_class = REGISTRY.fetch(session.session_shape.name) do
        raise UnknownShapeError, "No calculator registered for session shape #{session.session_shape.name.inspect}"
      end

      calculator_class.new(session)
    end
  end
end
