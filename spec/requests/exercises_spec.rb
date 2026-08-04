require "rails_helper"

RSpec.describe "Exercises", type: :request do
  describe "GET /exercises" do
    it "lists existing exercises" do
      create(:exercise, name: "360", equipment: create(:equipment, name: "Mace"))

      get exercises_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mace")
      expect(response.body).to include("360")
    end

    it "warns how many logged sessions would be deleted alongside an exercise" do
      exercise = create(:exercise)
      create(:session, exercise: exercise)

      get exercises_path

      expect(response.body).to include("This will also delete 1 logged session")
    end

    it "uses a plain confirmation when an exercise has no logged sessions" do
      create(:exercise)

      get exercises_path

      expect(response.body).to include("Delete this exercise?")
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
      equipment = create(:equipment, name: "Mace")

      expect {
        post exercises_path, params: { exercise: { name: "10-2", arm: "double", equipment_id: equipment.id, notes: "" } }
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

  describe "GET /exercises/:id/edit" do
    it "renders the edit form pre-filled with the exercise's attributes" do
      exercise = create(:exercise, name: "10-2", equipment: create(:equipment, name: "Mace"))

      get edit_exercise_path(exercise)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("10-2")
    end
  end

  describe "PATCH /exercises/:id" do
    it "updates the exercise and redirects to the index" do
      exercise = create(:exercise, name: "Snatch", arm: "double")

      patch exercise_path(exercise), params: { exercise: { name: "Snatch", arm: "single" } }

      expect(response).to redirect_to(exercises_path)
      expect(exercise.reload.arm).to eq("single")
    end

    it "re-renders the form with errors when invalid" do
      exercise = create(:exercise)

      patch exercise_path(exercise), params: { exercise: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(exercise.reload.name).to be_present
    end
  end

  describe "DELETE /exercises/:id" do
    it "deletes an exercise with no logged sessions" do
      exercise = create(:exercise)

      expect { delete exercise_path(exercise) }.to change(Exercise, :count).by(-1)

      expect(response).to redirect_to(exercises_path)
    end

    it "deletes an exercise along with its logged sessions and sets" do
      exercise = create(:exercise)
      session = create(:session, exercise: exercise)
      create(:session_set, session: session, set_number: 1, reps: 20)

      expect { delete exercise_path(exercise) }.to change(Exercise, :count).by(-1)
        .and change(Session, :count).by(-1)
        .and change(SessionSet, :count).by(-1)
    end
  end
end
