require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /sessions/new" do
    it "renders the form when exercises exist" do
      create(:exercise)

      get new_session_path

      expect(response).to have_http_status(:ok)
    end

    it "prompts to add an exercise first when none exist" do
      get new_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("You need an exercise")
    end
  end

  describe "POST /sessions" do
    let(:exercise) { create(:exercise) }

    let(:valid_params) do
      {
        date: "2026-07-30",
        exercise_id: exercise.id,
        planned_weight_kg: "10.0",
        planned_work_seconds: "300",
        planned_rest_seconds: "600",
        planned_sets: "5"
      }
    end

    it "creates a session with the interval_work shape and redirects to it" do
      expect {
        post sessions_path, params: { session: valid_params }
      }.to change(Session, :count).by(1)

      expect(Session.last.session_shape.name).to eq(SessionShape::INTERVAL_WORK)
      expect(response).to redirect_to(session_path(Session.last))
    end

    it "re-renders the form with errors when invalid" do
      expect {
        post sessions_path, params: { session: valid_params.merge(planned_work_seconds: "") }
      }.not_to change(Session, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /sessions/:id" do
    it "shows session details and computed outputs" do
      session = create(:session, planned_weight_kg: 10, planned_work_seconds: 300, planned_rest_seconds: 600)
      create(:session_set, session: session, set_number: 1, reps: 20)

      get session_path(session)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(session.exercise.name)
    end

    it "shows a placeholder when there isn't enough progression data yet" do
      session = create(:session)

      get session_path(session)

      expect(response.body).to include("Not enough data yet")
    end

    it "renders a pace chart once a comparable session has data" do
      session = create(:session, planned_weight_kg: 10, planned_work_seconds: 300)
      create(:session_set, session: session, set_number: 1, reps: 20)

      get session_path(session)

      expect(response.body).to include("Pace progression")
      expect(response.body).not_to include("Not enough data yet")
    end
  end
end
