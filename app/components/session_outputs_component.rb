class SessionOutputsComponent < ViewComponent::Base
  def initialize(calculator:)
    @calculator = calculator
  end

  def outputs
    @calculator.display_outputs
  end
end
