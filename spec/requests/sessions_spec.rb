require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /sessions/new" do
    it "renders the form when exercises exist" do
      create(:exercise)

      get new_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Interval work", "Fixed reps for time", "EMOM")
    end

    it "prompts to add an exercise first when none exist" do
      get new_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("You need an exercise")
    end

    it "prefills the form from a benchmark_preset_id param" do
      preset = create(:benchmark_preset, name: "Monthly 3x5", planned_weight_kg: 12, planned_sets: 3)

      get new_session_path(benchmark_preset_id: preset.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Starting from benchmark preset: Monthly 3x5")
      expect(response.body).to include('value="12.0"')
    end
  end

  describe "POST /sessions" do
    let(:exercise) { create(:exercise) }
    let(:interval_work_shape) { create(:session_shape, :interval_work) }
    let(:fixed_reps_for_time_shape) { create(:session_shape, :fixed_reps_for_time) }
    let(:emom_shape) { create(:session_shape, :emom) }

    let(:valid_params) do
      {
        date: "2026-07-30",
        exercise_id: exercise.id,
        session_shape_id: interval_work_shape.id,
        planned_weight_kg: "10.0",
        planned_work_seconds: "300",
        planned_rest_seconds: "600",
        planned_sets: "5"
      }
    end

    it "creates an interval_work session and redirects to it" do
      expect {
        post sessions_path, params: { session: valid_params }
      }.to change(Session, :count).by(1)

      expect(Session.last.session_shape.name).to eq(SessionShape::INTERVAL_WORK)
      expect(response).to redirect_to(session_path(Session.last))
    end

    it "creates a fixed_reps_for_time session" do
      params = {
        date: "2026-07-30", exercise_id: exercise.id, session_shape_id: fixed_reps_for_time_shape.id,
        planned_weight_kg: "10.0", target_reps: "100"
      }

      post sessions_path, params: { session: params }

      expect(Session.last.session_shape.name).to eq(SessionShape::FIXED_REPS_FOR_TIME)
      expect(response).to redirect_to(session_path(Session.last))
    end

    it "creates an emom session" do
      params = {
        date: "2026-07-30", exercise_id: exercise.id, session_shape_id: emom_shape.id,
        planned_weight_kg: "10.0", target_reps_per_minute: "20"
      }

      post sessions_path, params: { session: params }

      expect(Session.last.session_shape.name).to eq(SessionShape::EMOM)
      expect(response).to redirect_to(session_path(Session.last))
    end

    it "re-renders the form with errors when invalid" do
      expect {
        post sessions_path, params: { session: valid_params.merge(planned_work_seconds: "") }
      }.not_to change(Session, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "attaches a benchmark_preset and marks the session as a benchmark" do
      preset = create(:benchmark_preset, exercise: exercise, session_shape: interval_work_shape)

      post sessions_path, params: { session: valid_params.merge(benchmark_preset_id: preset.id) }

      expect(Session.last.benchmark_preset).to eq(preset)
      expect(Session.last.is_benchmark).to eq(true)
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

    it "does not render a pace chart for fixed_reps_for_time sessions" do
      session = create(:session, :fixed_reps_for_time)

      get session_path(session)

      expect(response.body).not_to include("Pace progression")
    end

    it "does not render a pace chart for emom sessions" do
      session = create(:session, :emom)

      get session_path(session)

      expect(response.body).not_to include("Pace progression")
    end

    it "shows a benchmark badge for benchmark sessions" do
      session = create(:session, is_benchmark: true)

      get session_path(session)

      expect(response.body).to include("Benchmark")
    end

    it "includes non-benchmark sessions in the pace chart by default" do
      training = create(:session, date: "2026-01-01", planned_weight_kg: 10,
                                   planned_work_seconds: 300, is_benchmark: false)
      create(:session_set, session: training, set_number: 1, reps: 20)
      benchmark = create(:session, exercise: training.exercise, date: "2026-06-01", planned_weight_kg: 10,
                                    planned_work_seconds: 300, is_benchmark: true)
      create(:session_set, session: benchmark, set_number: 1, reps: 30)

      get session_path(benchmark)

      expect(response.body).to include(training.date.to_s)
    end

    it "excludes non-benchmark sessions from the pace chart when benchmarks_only is set" do
      training = create(:session, date: "2026-01-01", planned_weight_kg: 10,
                                   planned_work_seconds: 300, is_benchmark: false)
      create(:session_set, session: training, set_number: 1, reps: 20)
      benchmark = create(:session, exercise: training.exercise, date: "2026-06-01", planned_weight_kg: 10,
                                    planned_work_seconds: 300, is_benchmark: true)
      create(:session_set, session: benchmark, set_number: 1, reps: 30)

      get session_path(benchmark, benchmarks_only: "true")

      expect(response.body).not_to include(training.date.to_s)
      expect(response.body).to include(benchmark.date.to_s)
    end
  end
end
