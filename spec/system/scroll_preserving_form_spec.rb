require "rails_helper"

RSpec.describe "Scroll-preserving filter forms", type: :system, js: true do
  it "restores scroll position after an auto-submitting filter reloads the page" do
    exercise = create(:exercise, name: "10-2", equipment: create(:equipment, name: "Mace"))
    30.times do |i|
      session = create(:session, exercise: exercise, date: Date.new(2026, 1, 1) + i, weight_kg: 10)
      create(:session_set, session: session, set_number: 1, reps: 20)
    end

    visit stats_path
    page.execute_script("window.scrollTo(0, 600)")
    scroll_before = page.evaluate_script("window.scrollY")

    # Changing the value and dispatching "change" directly (rather than Capybara's `choose`,
    # which drives a native click) avoids Selenium's own scroll-target-into-view behavior, which
    # would otherwise move the page before the interaction even happens and confound the check —
    # a real click can only ever happen on a control the user can already see, so it never
    # triggers that native auto-scroll in practice.
    page.execute_script(<<~JS)
      const radio = document.querySelector('input[type=radio][name=period][value=weekly]')
      radio.checked = true
      radio.dispatchEvent(new Event('change', { bubbles: true }))
    JS

    expect(page).to have_checked_field("Weekly")
    scroll_after = page.evaluate_script("window.scrollY")

    expect(scroll_after).to be_within(50).of(scroll_before)
  end
end
