require "rails_helper"

RSpec.describe "BenchmarkPresets", type: :request do
  describe "GET /benchmark_presets" do
    it "lists existing presets with a start-session link" do
      preset = create(:benchmark_preset, name: "Monthly 3x5")

      get benchmark_presets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Monthly 3x5")
      expect(response.body).to include(new_session_path(benchmark_preset_id: preset.id))
    end
  end

  describe "GET /benchmark_presets/new" do
    it "renders the form when exercises exist" do
      create(:exercise)

      get new_benchmark_preset_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /benchmark_presets" do
    let(:exercise) { create(:exercise) }
    let(:shape) { create(:session_shape, :interval_work) }

    it "creates a preset and redirects to the index" do
      params = {
        name: "Monthly 3x5", exercise_id: exercise.id, session_shape_id: shape.id,
        planned_weight_kg: "10.0", planned_work_seconds: "300", planned_rest_seconds: "600", planned_sets: "3"
      }

      expect {
        post benchmark_presets_path, params: { benchmark_preset: params }
      }.to change(BenchmarkPreset, :count).by(1)

      expect(response).to redirect_to(benchmark_presets_path)
    end

    it "re-renders the form with errors when invalid" do
      expect {
        post benchmark_presets_path, params: { benchmark_preset: { name: "" } }
      }.not_to change(BenchmarkPreset, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
