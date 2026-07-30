require "rails_helper"

RSpec.describe "Stats", type: :request do
  describe "GET /stats" do
    it "shows lifetime totals across all exercises" do
      session = create(:session, planned_weight_kg: 10)
      create(:session_set, session: session, set_number: 1, reps: 20)

      get stats_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("20")
      expect(response.body).to include("200")
    end

    it "filters totals to a single exercise when exercise_id is given" do
      mace = create(:exercise, name: "Mace 360")
      kettlebell = create(:exercise, name: "Kettlebell Swing")
      mace_session = create(:session, exercise: mace, planned_weight_kg: 10)
      create(:session_set, session: mace_session, set_number: 1, reps: 20)
      kettlebell_session = create(:session, exercise: kettlebell, planned_weight_kg: 16)
      create(:session_set, session: kettlebell_session, set_number: 1, reps: 15)

      get stats_path(exercise_id: mace.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("20")
    end

    it "shows a placeholder when nothing has been logged" do
      get stats_path

      expect(response.body).to include("No sets logged yet")
    end
  end
end
