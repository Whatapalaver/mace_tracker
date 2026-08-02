require "rails_helper"

# The shape-conditional field toggling this spec exercises now lives on the benchmark preset
# form (shared/_shape_fields.html.erb) — the session log form moved to a single formula field
# for all three shapes (no toggling needed), covered instead by spec/system/session_logging_spec.rb.
RSpec.describe "Shape-aware benchmark preset form", type: :system, js: true do
  before do
    create(:exercise, name: "Mace 360")
    create(:session_shape, :interval_work)
    create(:session_shape, :fixed_reps_for_time)
    create(:session_shape, :emom)
  end

  it "shows only the fields relevant to the selected shape" do
    visit new_benchmark_preset_path

    expect(page).to have_field("Work (sec)", visible: :visible)
    expect(page).to have_field("Reps", visible: :hidden)
    expect(page).to have_field("Reps / min", visible: :hidden)

    choose "Fixed reps for time"

    expect(page).to have_field("Reps", visible: :visible)
    expect(page).to have_field("Work (sec)", visible: :hidden)
    expect(page).to have_field("Reps / min", visible: :hidden)

    choose "EMOM"

    expect(page).to have_field("Reps / min", visible: :visible)
    expect(page).to have_field("Work (sec)", visible: :hidden)
    expect(page).to have_field("Reps", visible: :hidden)

    choose "Interval work"

    expect(page).to have_field("Work (sec)", visible: :visible)
  end

  it "submits a fixed_reps_for_time preset end to end" do
    visit new_benchmark_preset_path
    fill_in "Preset name", with: "My Preset"
    select "Mace 360", from: "Exercise"
    choose "Fixed reps for time"
    fill_in "Weight (kg)", with: "10"
    fill_in "Reps", with: "100"

    click_button "Add preset"

    expect(page).to have_content("My Preset")
  end
end
