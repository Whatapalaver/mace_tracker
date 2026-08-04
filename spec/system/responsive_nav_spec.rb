require "rails_helper"

RSpec.describe "Responsive nav", type: :system, js: true do
  it "hides the inline nav and reveals a toggleable menu on a narrow viewport" do
    page.driver.browser.manage.window.resize_to(375, 667)

    visit stats_path

    expect(page).not_to have_link("Exercises", visible: :visible)
    expect(page).to have_css("button[aria-label='Menu']", visible: :visible)

    find("button[aria-label='Menu']").click

    expect(page).to have_link("Exercises", visible: :visible)
    click_link "Exercises"

    expect(page).to have_current_path(exercises_path)
  end

  it "shows the inline nav and hides the menu button on a wide viewport" do
    page.driver.browser.manage.window.resize_to(1280, 800)

    visit stats_path

    expect(page).to have_link("Exercises", visible: :visible)
    expect(page).not_to have_css("button[aria-label='Menu']", visible: :visible)
  end
end
