require "rails_helper"

RSpec.describe "Stats", type: :request do
  describe "GET /stats" do
    it "shows lifetime totals across all exercises" do
      session = create(:session, weight_kg: 10)
      create(:session_set, session: session, set_number: 1, reps: 20)

      get stats_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("20")
      expect(response.body).to include("200")
    end

    it "filters totals to a single exercise when exercise_id is given" do
      mace = create(:exercise, name: "Mace 360")
      kettlebell = create(:exercise, name: "Kettlebell Swing")
      mace_session = create(:session, exercise: mace, weight_kg: 10)
      create(:session_set, session: mace_session, set_number: 1, reps: 20)
      kettlebell_session = create(:session, exercise: kettlebell, weight_kg: 16)
      create(:session_set, session: kettlebell_session, set_number: 1, reps: 15)

      get stats_path(exercise_id: mace.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("20")
    end

    it "shows a placeholder when nothing has been logged" do
      get stats_path

      expect(response.body).to include("No sets logged yet")
    end

    it "does not show the shape selector until an exercise is chosen" do
      get stats_path

      expect(response.body).not_to include("Choose a shape")
    end

    it "shows the shape selector once an exercise is chosen" do
      exercise = create(:exercise)

      get stats_path(exercise_id: exercise.id)

      expect(response.body).to include("Choose a shape")
    end

    it "lists distinct signatures for the chosen exercise and shape, without baking in a weight" do
      exercise = create(:exercise)
      shape = create(:session_shape, :interval_work)
      create(:session, exercise: exercise, session_shape: shape, weight_kg: 10, work_seconds: 300)
      create(:session, exercise: exercise, session_shape: shape, weight_kg: 12, work_seconds: 180)

      get stats_path(exercise_id: exercise.id, shape: SessionShape::INTERVAL_WORK)

      expect(response.body).to include("5(5mw+10mr)")
      expect(response.body).to include("5(3mw+10mr)")
      expect(response.body).not_to include("5(5mw+10mr)@10kg")
      expect(response.body).not_to include("5(3mw+10mr)@12kg")
    end

    it "charts the requested output across sessions sharing a signature" do
      exercise = create(:exercise)
      shape = create(:session_shape, :interval_work)
      session = create(:session, exercise: exercise, session_shape: shape,
                                  weight_kg: 10, work_seconds: 300, date: "2026-07-01")
      create(:session_set, session: session, set_number: 1, reps: 20, duration_seconds: 300)

      get stats_path(exercise_id: exercise.id, shape: SessionShape::INTERVAL_WORK, structural_value: 300)

      expect(response.body).to include("Best pace")
      expect(response.body).to include(session.date.to_s)
    end

    it "switches series when a different output is requested" do
      exercise = create(:exercise)
      shape = create(:session_shape, :interval_work)
      session = create(:session, exercise: exercise, session_shape: shape,
                                  weight_kg: 10, work_seconds: 300)
      create(:session_set, session: session, set_number: 1, reps: 20, duration_seconds: 300)

      get stats_path(exercise_id: exercise.id, shape: SessionShape::INTERVAL_WORK,
                      structural_value: 300, output: "Total output")

      expect(response.body).to include("200")
    end

    it "groups by weight by default and lets a specific weight be locked" do
      exercise = create(:exercise)
      shape = create(:session_shape, :interval_work)
      light = create(:session, exercise: exercise, session_shape: shape,
                                weight_kg: 8, work_seconds: 300, date: "2026-07-01")
      create(:session_set, session: light, set_number: 1, reps: 20, duration_seconds: 300)
      heavy = create(:session, exercise: exercise, session_shape: shape,
                                weight_kg: 10, work_seconds: 300, date: "2026-07-08")
      create(:session_set, session: heavy, set_number: 1, reps: 25, duration_seconds: 300)

      get stats_path(exercise_id: exercise.id, shape: SessionShape::INTERVAL_WORK, structural_value: 300)
      chart_script = response.body[/createChart[\s\S]*?;/]
      expect(chart_script).to include('"8.0kg"', '"10.0kg"')

      get stats_path(exercise_id: exercise.id, shape: SessionShape::INTERVAL_WORK,
                      structural_value: 300, weight: "10")
      chart_script = response.body[/createChart[\s\S]*?;/]
      expect(chart_script).to include('"10.0kg"')
      expect(chart_script).not_to include('"8.0kg"')
    end

    it "passes multi-series chart data as an array of {name, data} objects, not an array of pairs" do
      # Chartkick 5's JS only recognizes multi-series data when the top-level payload is an
      # array of plain objects (Array#chart_json's {name:, data:} shape) — passing a Ruby Hash
      # of {series_name => {date => value}} straight to line_chart instead serializes as a flat
      # array of [name, data] pairs (Hash#chart_json's fallback), which Chart.js silently
      # misreads as a single series with the series names as x-axis categories.
      exercise = create(:exercise)
      shape = create(:session_shape, :interval_work)
      light = create(:session, exercise: exercise, session_shape: shape, weight_kg: 8, work_seconds: 300)
      create(:session_set, session: light, set_number: 1, reps: 20, duration_seconds: 300)
      heavy = create(:session, exercise: exercise, session_shape: shape, weight_kg: 10, work_seconds: 300)
      create(:session_set, session: heavy, set_number: 1, reps: 25, duration_seconds: 300)

      get stats_path(exercise_id: exercise.id, shape: SessionShape::INTERVAL_WORK, structural_value: 300)
      chart_script = response.body[/createChart[\s\S]*?;/]
      data_json = chart_script[/new Chartkick\["LineChart"\]\("chart-1", (.*), \{/, 1]
      data = JSON.parse(data_json)

      expect(data).to all(include("name", "data"))
      expect(data.map { |series| series["name"] }).to contain_exactly("8.0kg", "10.0kg")
    end
  end
end
