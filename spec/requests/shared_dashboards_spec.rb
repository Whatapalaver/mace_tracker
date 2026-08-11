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

    it "lets an unscoped visitor pick any equipment/exercise, same as the owner's stats page" do
      mace = create(:exercise, name: "360", equipment: create(:equipment, name: "Mace"))
      kettlebell = create(:exercise, name: "Swing", equipment: create(:equipment, name: "Kettlebell"))
      share_link = create(:share_link)

      get shared_dashboard_path(token: share_link.token)

      expect(response.body).to include("Mace 360")
      expect(response.body).to include("Kettlebell Swing")
      expect(response.body).to include(">Equipment<")
    end

    it "locks a scoped visitor to the one exercise, with no equipment/exercise picker" do
      mace = create(:exercise, name: "360", equipment: create(:equipment, name: "Mace"))
      share_link = create(:share_link, :scoped_to_exercise, exercise: mace)

      get shared_dashboard_path(token: share_link.token)

      selects = response.body.scan(/<select[^>]*>/)

      expect(response.body).to include("Mace 360")
      expect(response.body).not_to include(">Equipment<")
      expect(selects.grep(/name="equipment_id"/)).to be_empty
      expect(selects.grep(/name="exercise_id"/)).to be_empty
    end

    it "lets an unscoped visitor filter by a specific tool via the shared stats page" do
      mace = create(:equipment, name: "Mace")
      exercise = create(:exercise, equipment: mace)
      eryx = create(:tool, name: "Eryx Adjustable", equipment: mace)
      wrecking_ball = create(:tool, name: "Wrecking Ball", equipment: mace)
      eryx_session = create(:session, exercise: exercise, tool: eryx, weight_kg: 10)
      create(:session_set, session: eryx_session, set_number: 1, reps: 20)
      wrecking_ball_session = create(:session, exercise: exercise, tool: wrecking_ball, weight_kg: 10)
      create(:session_set, session: wrecking_ball_session, set_number: 1, reps: 15)
      share_link = create(:share_link)

      get shared_dashboard_path(token: share_link.token, equipment_id: "tool-#{eryx.id}")

      expect(response.body).to include("20")
      expect(response.body).not_to include("35")
    end

    it "lets a visitor browse shape/signature progression, same as the owner's stats page" do
      exercise = create(:exercise, name: "360", equipment: create(:equipment, name: "Mace"))
      shape = create(:session_shape, :interval_work)
      session = create(:session, exercise: exercise, session_shape: shape,
                                  weight_kg: 10, work_seconds: 300, rest_seconds: 600, sets_count: 5)
      create(:session_set, session: session, set_number: 1, reps: 20, duration_seconds: 300)
      share_link = create(:share_link, :scoped_to_exercise, exercise: exercise)

      get shared_dashboard_path(token: share_link.token, shape: SessionShape::INTERVAL_WORK,
                                  structural_value: "300:600:5")

      expect(response.body).to include("10.0kg")
    end
  end

  describe "GET /shared/:token/sessions" do
    it "lists sessions with no edit or delete controls" do
      exercise = create(:exercise, name: "360", equipment: create(:equipment, name: "Mace"))
      session = create(:session, exercise: exercise, date: Date.new(2026, 3, 10))
      create(:session_set, session: session, set_number: 1, reps: 20)
      share_link = create(:share_link)

      get shared_dashboard_sessions_path(token: share_link.token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mace 360")
      expect(response.body).not_to include(">Edit<")
      expect(response.body).not_to include(">Delete<")
    end

    it "restricts sessions to the scoped exercise and hides the equipment/exercise filter" do
      mace = create(:exercise, name: "360", equipment: create(:equipment, name: "Mace"))
      kettlebell = create(:exercise, name: "Swing", equipment: create(:equipment, name: "Kettlebell"))
      create(:session, exercise: mace, date: Date.new(2026, 3, 10))
      create(:session, exercise: kettlebell, date: Date.new(2026, 3, 11))
      share_link = create(:share_link, :scoped_to_exercise, exercise: mace)

      get shared_dashboard_sessions_path(token: share_link.token)

      expect(response.body).to include("Mace 360")
      expect(response.body).not_to include("Kettlebell Swing")
      expect(response.body).not_to include(">Equipment<")
    end

    it "supports filtering by a specific tool via the grouped equipment/tool select" do
      mace = create(:equipment, name: "Mace")
      exercise = create(:exercise, equipment: mace)
      eryx = create(:tool, name: "Eryx Adjustable", equipment: mace)
      wrecking_ball = create(:tool, name: "Wrecking Ball", equipment: mace)
      create(:session, exercise: exercise, tool: eryx, date: Date.new(2026, 3, 10))
      create(:session, exercise: exercise, tool: wrecking_ball, date: Date.new(2026, 3, 11))
      share_link = create(:share_link)

      get shared_dashboard_sessions_path(token: share_link.token, equipment_id: "tool-#{eryx.id}")

      expect(response.body).to include("10 Mar")
      expect(response.body).not_to include("11 Mar")
    end

    it "supports the year/month filters, same as the owner's history page" do
      exercise = create(:exercise)
      create(:session, exercise: exercise, date: Date.new(2025, 6, 15))
      create(:session, exercise: exercise, date: Date.new(2026, 3, 10))
      share_link = create(:share_link)

      get shared_dashboard_sessions_path(token: share_link.token, year: 2026)

      expect(response.body).to include("10 Mar")
      expect(response.body).not_to include("15 Jun")
    end

    it "404s for an unknown token" do
      get shared_dashboard_sessions_path(token: "nonexistent")

      expect(response).to have_http_status(:not_found)
    end
  end
end
