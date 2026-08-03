require "rails_helper"

RSpec.describe "SharedDashboards", type: :request do
  describe "GET /shared/:token" do
    it "renders the dashboard for a valid, unexpired token" do
      exercise = create(:exercise, name: "360", equipment: create(:equipment, name: "Mace"))
      session = create(:session, exercise: exercise, weight_kg: 10)
      create(:session_set, session: session, set_number: 1, reps: 20)
      share_link = create(:share_link)

      get shared_dashboard_path(token: share_link.token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mace 360")
      expect(response.body).to include("20")
    end

    it "restricts sessions to the scoped exercise" do
      mace = create(:exercise, name: "360", equipment: create(:equipment, name: "Mace"))
      kettlebell = create(:exercise, name: "Swing", equipment: create(:equipment, name: "Kettlebell"))
      create(:session, exercise: mace)
      create(:session, exercise: kettlebell)
      share_link = create(:share_link, :scoped_to_exercise, exercise: mace)

      get shared_dashboard_path(token: share_link.token)

      expect(response.body).to include("Mace 360")
      expect(response.body).not_to include("Kettlebell Swing")
    end

    it "404s for an unknown token" do
      get shared_dashboard_path(token: "nonexistent")

      expect(response).to have_http_status(:not_found)
    end

    it "404s for an expired token" do
      share_link = create(:share_link, :expired)

      get shared_dashboard_path(token: share_link.token)

      expect(response).to have_http_status(:not_found)
    end

    it "does not render the authenticated app navigation" do
      share_link = create(:share_link)

      get shared_dashboard_path(token: share_link.token)

      expect(response.body).not_to include(">Log<")
      expect(response.body).to include("read-only")
    end
  end
end
