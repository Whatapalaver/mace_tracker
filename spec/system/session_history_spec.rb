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

  it "saves a fixed_reps_for_time session's edit without touching the signature field" do
    # Regression: the signature field used to pre-fill with the display text ("108 reps"), but
    # the parser only accepts a bare number — so opening the edit row and saving unchanged
    # crashed immediately with "Expected a whole number".
    session = create(:session, :fixed_reps_for_time, reps: 108, weight_kg: 8)
    create(:session_set, session: session, set_number: 1, reps: 108, duration_seconds: 240)

    visit sessions_path
    click_link "Edit"
    click_button "Save"

    expect(page).to have_current_path(sessions_path)
    expect(page).not_to have_content("Expected a whole number")
    session.reload
    expect(session.reps).to eq(108)
  end

  it "changes a session's exercise via the edit row" do
    other_exercise = create(:exercise, name: "Snatch", equipment: create(:equipment, name: "Kettlebell"))
    session = create(:session, :fixed_reps_for_time, reps: 20)
    create(:session_set, session: session, set_number: 1, reps: 20, duration_seconds: 60)

    visit sessions_path
    click_link "Edit"
    select other_exercise.display_name, from: "session[exercise_id]"
    click_button "Save"

    expect(page).to have_content("Kettlebell Snatch")
    session.reload
    expect(session.exercise).to eq(other_exercise)
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

  it "keeps the Edit link on-screen at in-between viewport widths, not clipped by an overflowing wide table" do
    # Regression: the desktop grid switched on at md: (768px) but the page container didn't
    # widen enough to fit it until lg: (1024px), so between those two breakpoints the 9-column
    # table overflowed its box and pushed the Actions column past the visible viewport — Capybara
    # still considered the (scrolled-off) link "visible" since it wasn't display:none, so this
    # checks its actual on-screen position instead.
    create(:session)
    viewport_width = 900
    page.driver.browser.manage.window.resize_to(viewport_width, 800)

    visit sessions_path
    edit_link = find_link("Edit", visible: :visible)
    right_edge = edit_link.native.rect.x + edit_link.native.rect.width

    expect(right_edge).to be <= viewport_width
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
