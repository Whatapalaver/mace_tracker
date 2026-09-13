require "rails_helper"

RSpec.describe "Notation-driven session logging", type: :system, js: true do
  before do
    create(:exercise, name: "360", equipment: create(:equipment, name: "Mace"))
    create(:session_shape, :interval_work)
    create(:session_shape, :sets_and_reps)
    create(:session_shape, :fixed_reps_for_time)
    create(:session_shape, :emom)
  end

  it "logs an interval_work session in one step from a signature and reps list" do
    visit new_session_path
    select "Mace 360", from: "Exercise"
    fill_in "Shape", with: "3(5mw+5mr)"
    fill_in "Weight (kg)", with: "10"
    fill_in "Reps", with: "20, 19, 18"

    click_button "Save session"

    expect(page).to have_content("Mace 360")
    expect(page).to have_content("Session logged")
  end

  it "logs a bare-number sets_and_reps session, including a per-set weight override" do
    visit new_session_path
    select "Mace 360", from: "Exercise"
    fill_in "Shape", with: "100"
    fill_in "Weight (kg)", with: "6"
    fill_in "Reps", with: "100@6, 100@6, 50@8"

    click_button "Save session"

    expect(page).to have_content("Session logged")
  end

  it "logs a fixed_reps_for_time session via the collapsed advanced section and review step" do
    visit new_session_path
    select "Mace 360", from: "Exercise"
    find("summary", text: "Logging fixed reps for time or EMOM instead?").click
    choose "Fixed reps for time"
    fill_in "Formula", with: "3(108@10kg)"

    click_button "Save session"

    expect(page).to have_content("Set 1")
    expect(page).to have_content("Set 3")

    fill_in_all_reps_fields(with: "20")

    click_button "Save session"

    expect(page).to have_content("Mace 360")
    expect(page).to have_content("Session logged")
  end

  it "logs an emom session immediately via the collapsed advanced section, with no review step" do
    visit new_session_path
    select "Mace 360", from: "Exercise"
    find("summary", text: "Logging fixed reps for time or EMOM instead?").click
    choose "EMOM"
    fill_in "Formula", with: "10(20@10kg)"

    click_button "Save session"

    expect(page).to have_content("Session logged")
    expect(page).to have_content("Sets completed")
  end

  def fill_in_all_reps_fields(with:)
    all("input[data-fill-down-target]").each { |field| field.set(with) }
  end
end
