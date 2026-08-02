require "rails_helper"

RSpec.describe "Session history table", type: :system, js: true do
  it "edits a session's signature, weight, reps, and benchmark flag in place via the Turbo Frame row" do
    session = create(:session, date: Date.new(2026, 7, 1), weight_kg: 10, work_seconds: 300,
                                rest_seconds: 300, sets_count: 3, is_benchmark: false)
    create(:session_set, session: session, set_number: 1, reps: 20)
    create(:session_set, session: session, set_number: 2, reps: 19)
    create(:session_set, session: session, set_number: 3, reps: 18)

    visit sessions_path
    click_link "Edit"

    fill_in "session[signature]", with: "5(5mw+5mr)"
    fill_in "session[weight_kg]", with: "12"
    fill_in "session[reps_list]", with: "25, 24, 23, 22, 21"
    check "session[is_benchmark]"
    click_button "Save"

    expect(page).to have_content("5(5mw+5mr)")
    expect(page).to have_content("25, 24, 23, 22, 21")
    expect(page).to have_content("BENCHMARK") # uppercased via CSS text-transform
    expect(page).to have_current_path(sessions_path)

    session.reload
    expect(session.work_seconds).to eq(300)
    expect(session.rest_seconds).to eq(300)
    expect(session.sets_count).to eq(5)
    expect(session.weight_kg).to eq(12)
    expect(session.is_benchmark).to eq(true)
    expect(session.session_sets.order(:set_number).pluck(:reps)).to eq([ 25, 24, 23, 22, 21 ])
  end

  it "shows a validation error without saving when the signature and reps count disagree" do
    session = create(:session, work_seconds: 300, rest_seconds: 300, sets_count: 3)
    create(:session_set, session: session, set_number: 1, reps: 20)
    create(:session_set, session: session, set_number: 2, reps: 19)
    create(:session_set, session: session, set_number: 3, reps: 18)

    visit sessions_path
    click_link "Edit"
    fill_in "session[reps_list]", with: "20, 19"
    click_button "Save"

    expect(page).to have_content("Signature implies 3 sets but 2 rep values were given")
    session.reload
    expect(session.session_sets.count).to eq(3)
  end

  it "deletes a session and all its sets from the table" do
    session = create(:session)
    create(:session_set, session: session, set_number: 1)

    visit sessions_path
    accept_confirm { click_button "Delete" }

    expect(page).to have_content("No sessions logged yet")
    expect(Session.exists?(session.id)).to be false
  end
end
