require "rails_helper"

RSpec.describe "Notation-driven session logging", type: :system, js: true do
  before do
    create(:exercise, name: "Mace 360")
    create(:session_shape, :interval_work)
    create(:session_shape, :fixed_reps_for_time)
    create(:session_shape, :emom)
  end

  it "logs an interval_work session end to end via the formula and review step" do
    visit new_session_path
    select "Mace 360", from: "Exercise"
    fill_in "Formula", with: "3(5mw+5mr)@10kg"

    click_button "Continue"

    expect(page).to have_content("Set 1")
    expect(page).to have_content("Set 3")

    fill_in_all_reps_fields(with: "20")

    click_button "Save session"

    expect(page).to have_content("Mace 360")
    expect(page).to have_content("Session logged")
  end

  it "logs an emom session immediately, with no review step" do
    visit new_session_path
    select "Mace 360", from: "Exercise"
    choose "EMOM"
    fill_in "Formula", with: "10(20@10kg)"

    click_button "Continue"

    expect(page).to have_content("Session logged")
    expect(page).to have_content("Sets completed")
  end

  def fill_in_all_reps_fields(with:)
    all("input[type=number]").each { |field| field.set(with) }
  end
end
