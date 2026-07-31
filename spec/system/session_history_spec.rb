require "rails_helper"

RSpec.describe "Session history table", type: :system, js: true do
  it "edits a set's fields in place via the Turbo Frame row, without leaving the page" do
    session = create(:session, date: Date.new(2026, 7, 1))
    create(:session_set, session: session, set_number: 1, reps: 20, weight_kg: 10)

    visit session_sets_path
    click_link "Edit"

    fill_in "session_set[reps]", with: "25"
    click_button "Save"

    expect(page).to have_content("25")
    expect(page).to have_current_path(session_sets_path)
    expect(page).to have_link("Edit")
  end

  it "deletes the whole session when its last set is removed from the table" do
    session = create(:session)
    create(:session_set, session: session, set_number: 1)

    visit session_sets_path
    accept_confirm { click_button "Delete" }

    expect(page).to have_content("No sessions logged yet")
    expect(Session.exists?(session.id)).to be false
  end
end
