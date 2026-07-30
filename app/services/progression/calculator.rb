module Progression
  class Calculator
    class UnknownShapeError < StandardError; end

    REGISTRY = {
      SessionShape::INTERVAL_WORK => IntervalWorkCalculator
    }.freeze

    def self.for(session)
      calculator_class = REGISTRY.fetch(session.session_shape.name) do
        raise UnknownShapeError, "No calculator registered for session shape #{session.session_shape.name.inspect}"
      end

      calculator_class.new(session)
    end
  end
end
