require "rails_helper"

RSpec.describe "Exercises", type: :request do
  describe "GET /exercises" do
    it "lists existing exercises" do
      create(:exercise, name: "Mace 360")

      get exercises_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mace 360")
    end
  end

  describe "GET /exercises/new" do
    it "renders the new exercise form" do
      get new_exercise_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /exercises" do
    it "creates an exercise and redirects to the index" do
      expect {
        post exercises_path, params: { exercise: { name: "10-2", arm: "double", notes: "" } }
      }.to change(Exercise, :count).by(1)

      expect(response).to redirect_to(exercises_path)
    end

    it "re-renders the form with errors when invalid" do
      expect {
        post exercises_path, params: { exercise: { name: "", arm: "double" } }
      }.not_to change(Exercise, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
