require "rails_helper"

RSpec.describe "Shape-aware session form", type: :system, js: true do
  before do
    create(:exercise, name: "Mace 360")
    create(:session_shape, :interval_work)
    create(:session_shape, :fixed_reps_for_time)
    create(:session_shape, :emom)
  end

  it "shows only the fields relevant to the selected shape" do
    visit new_session_path

    expect(page).to have_field("Work (sec)", visible: :visible)
    expect(page).to have_field("Target reps", visible: :hidden)
    expect(page).to have_field("Target reps / min", visible: :hidden)

    choose "Fixed reps for time"

    expect(page).to have_field("Target reps", visible: :visible)
    expect(page).to have_field("Work (sec)", visible: :hidden)
    expect(page).to have_field("Target reps / min", visible: :hidden)

    choose "EMOM"

    expect(page).to have_field("Target reps / min", visible: :visible)
    expect(page).to have_field("Work (sec)", visible: :hidden)
    expect(page).to have_field("Target reps", visible: :hidden)

    choose "Interval work"

    expect(page).to have_field("Work (sec)", visible: :visible)
  end

  it "submits a fixed_reps_for_time session end to end" do
    visit new_session_path
    select "Mace 360", from: "Exercise"
    choose "Fixed reps for time"
    fill_in "Weight (kg)", with: "10"
    fill_in "Target reps", with: "100"

    click_button "Start session"

    expect(page).to have_content("Target reps")
    expect(page).to have_content("100")
  end
end
