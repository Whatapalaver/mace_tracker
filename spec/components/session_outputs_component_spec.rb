require "rails_helper"

RSpec.describe SessionOutputsComponent, type: :component do
  it "renders each label/value pair from the calculator's display_outputs" do
    session = create(:session, planned_weight_kg: 10, planned_work_seconds: 300, planned_rest_seconds: 600)
    create(:session_set, session: session, set_number: 1, reps: 20)
    calculator = Progression::Calculator.for(session)

    render_inline(described_class.new(calculator: calculator))

    expect(page).to have_text("Best pace")
    expect(page).to have_text("Total output")
    expect(page).to have_text("200")
  end

  it "renders an em dash for metrics that can't be computed yet" do
    session = create(:session)
    calculator = Progression::Calculator.for(session)

    render_inline(described_class.new(calculator: calculator))

    expect(page).to have_text("—")
  end
end
