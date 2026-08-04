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

    it "defaults the period to monthly and buckets reps by month" do
      session = create(:session, weight_kg: 10, date: "2026-07-01")
      create(:session_set, session: session, set_number: 1, reps: 20)

      get stats_path

      expect(response.body).to include(Date.new(2026, 7, 1).beginning_of_month.to_s)
      monthly_radio = response.body[/<input[^>]*value="monthly"[^>]*>/]
      expect(monthly_radio).to include("checked")
    end

    it "switches to weekly buckets when period=weekly" do
      create(:session_set, session: create(:session, weight_kg: 10, date: "2026-07-01"), set_number: 1, reps: 20)
      create(:session_set, session: create(:session, weight_kg: 10, date: "2026-07-02"), set_number: 1, reps: 10)

      get stats_path(period: "weekly")

      weekly_radio = response.body[/<input[^>]*value="weekly"[^>]*>/]
      expect(weekly_radio).to include("checked")
      expect(response.body).to include(Date.new(2026, 7, 1).beginning_of_week.to_s)
      expect(response.body).not_to include("2026-07-02")
    end

    it "filters totals to a single exercise when exercise_id is given" do
      mace = create(:exercise, name: "360", equipment: create(:equipment, name: "Mace"))
      kettlebell = create(:exercise, name: "Swing", equipment: create(:equipment, name: "Kettlebell"))
      mace_session = create(:session, exercise: mace, weight_kg: 10)
      create(:session_set, session: mace_session, set_number: 1, reps: 20)
      kettlebell_session = create(:session, exercise: kettlebell, weight_kg: 16)
      create(:session_set, session: kettlebell_session, set_number: 1, reps: 15)

      get stats_path(exercise_id: mace.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("20")
    end

    it "narrows total reps to the selected equipment when no specific exercise is chosen" do
      mace_equipment = create(:equipment, name: "Mace")
      kettlebell_equipment = create(:equipment, name: "Kettlebell")
      mace_session = create(:session, exercise: create(:exercise, name: "360", equipment: mace_equipment), weight_kg: 10)
      create(:session_set, session: mace_session, set_number: 1, reps: 20)
      kettlebell_session = create(:session, exercise: create(:exercise, name: "Swing", equipment: kettlebell_equipment),
                                             weight_kg: 16)
      create(:session_set, session: kettlebell_session, set_number: 1, reps: 15)

      get stats_path(equipment_id: mace_equipment.id)

      expect(response.body).to include("20")
    end

    it "narrows the exercise dropdown to the selected equipment" do
      mace_equipment = create(:equipment, name: "Mace")
      kettlebell_equipment = create(:equipment, name: "Kettlebell")
      create(:exercise, name: "360", equipment: mace_equipment)
      create(:exercise, name: "Swing", equipment: kettlebell_equipment)

      get stats_path(equipment_id: mace_equipment.id)

      expect(response.body).to include("Mace 360")
      expect(response.body).not_to include("Kettlebell Swing")
    end

    it "drops an exercise selection that doesn't belong to a newly chosen equipment" do
      mace_equipment = create(:equipment, name: "Mace")
      kettlebell_equipment = create(:equipment, name: "Kettlebell")
      mace_exercise = create(:exercise, name: "360", equipment: mace_equipment)
      create(:exercise, name: "Swing", equipment: kettlebell_equipment)

      get stats_path(equipment_id: kettlebell_equipment.id, exercise_id: mace_exercise.id)

      expect(response.body).not_to include("Choose a shape")
    end

    it "defaults to Mace 10-2 on a fresh, filterless visit when it exists" do
      mace = create(:equipment, name: "Mace")
      mace_10_2 = create(:exercise, name: "10-2", equipment: mace)
      create(:exercise, name: "360", equipment: mace)

      get stats_path

      expect(response.body).to include(%(selected="selected" value="#{mace.id}"))
      expect(response.body).to include(%(selected="selected" value="#{mace_10_2.id}"))
    end

    it "does not override an explicitly cleared equipment/exercise filter with the default" do
      mace = create(:equipment, name: "Mace")
      create(:exercise, name: "10-2", equipment: mace)

      get stats_path(equipment_id: "", exercise_id: "")

      expect(response.body).not_to include(%(selected="selected" value="#{mace.id}"))
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

    it "defaults shape and signature to the first available once an exercise with sessions is chosen" do
      exercise = create(:exercise)
      shape = create(:session_shape, :interval_work)
      create(:session, exercise: exercise, session_shape: shape, weight_kg: 10, work_seconds: 300)

      get stats_path(exercise_id: exercise.id)

      expect(response.body).to include(%(selected="selected" value="#{shape.name}"))
      expect(response.body).to include("Best pace")
    end

    it "does not override an explicitly cleared shape with the default" do
      exercise = create(:exercise)
      shape = create(:session_shape, :interval_work)
      create(:session, exercise: exercise, session_shape: shape, weight_kg: 10, work_seconds: 300)

      get stats_path(exercise_id: exercise.id, shape: "")

      expect(response.body).not_to include(%(selected="selected" value="#{shape.name}"))
    end

    it "leaves shape and signature nil, without error, when the exercise has no sessions at all" do
      exercise = create(:exercise)

      get stats_path(exercise_id: exercise.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Choose a signature")
    end

    it "shows personal bests per weight once an exercise is chosen" do
      exercise = create(:exercise)
      light = create(:session, exercise: exercise, weight_kg: 8, date: "2026-06-01")
      create(:session_set, session: light, set_number: 1, reps: 30)
      heavy = create(:session, exercise: exercise, weight_kg: 10, date: "2026-07-05")
      create(:session_set, session: heavy, set_number: 1, reps: 25)

      get stats_path(exercise_id: exercise.id)

      expect(response.body).to include("Personal bests")
      expect(response.body).to include("8.0kg")
      expect(response.body).to include("10.0kg")
      expect(response.body).to include("30")
      expect(response.body).to include("25")
    end

    it "does not show personal bests until an exercise is chosen" do
      get stats_path

      expect(response.body).not_to include("Personal bests")
    end

    it "shows a max-reps-by-weight chart once an exercise is chosen" do
      exercise = create(:exercise)
      session = create(:session, exercise: exercise, weight_kg: 10, date: "2026-07-01")
      create(:session_set, session: session, set_number: 1, reps: 20)

      get stats_path(exercise_id: exercise.id)

      expect(response.body).to include("Max reps by weight")
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

    it "lists a coarser work-duration-only signature under segment granularity" do
      exercise = create(:exercise)
      shape = create(:session_shape, :interval_work)
      create(:session, exercise: exercise, session_shape: shape, weight_kg: 10,
                        work_seconds: 300, rest_seconds: 0, sets_count: 1)
      create(:session, exercise: exercise, session_shape: shape, weight_kg: 10,
                        work_seconds: 300, rest_seconds: 300, sets_count: 3)

      get stats_path(exercise_id: exercise.id, shape: SessionShape::INTERVAL_WORK, granularity: "segment")

      expect(response.body).to include("5mw")
      expect(response.body).not_to include("3(5mw+5mr)")
    end

    it "restricts outputs to pace metrics under segment granularity" do
      exercise = create(:exercise)
      shape = create(:session_shape, :interval_work)
      session = create(:session, exercise: exercise, session_shape: shape, weight_kg: 10, work_seconds: 300)
      create(:session_set, session: session, set_number: 1, reps: 20, duration_seconds: 300)

      get stats_path(exercise_id: exercise.id, shape: SessionShape::INTERVAL_WORK,
                      granularity: "segment", structural_value: "300")

      expect(response.body).to include("Best pace", "Avg pace")
      expect(response.body).not_to include('value="Total output"')
    end

    it "includes a multi-set session under segment granularity when its work duration matches" do
      exercise = create(:exercise)
      shape = create(:session_shape, :interval_work)
      single = create(:session, exercise: exercise, session_shape: shape, weight_kg: 10,
                                 work_seconds: 300, rest_seconds: 0, sets_count: 1, date: "2026-07-01")
      create(:session_set, session: single, set_number: 1, reps: 20, duration_seconds: 300)
      multi = create(:session, exercise: exercise, session_shape: shape, weight_kg: 10,
                                work_seconds: 300, rest_seconds: 300, sets_count: 3, date: "2026-07-08")
      create(:session_set, session: multi, set_number: 1, reps: 30, duration_seconds: 300)
      create(:session_set, session: multi, set_number: 2, reps: 25, duration_seconds: 300)

      get stats_path(exercise_id: exercise.id, shape: SessionShape::INTERVAL_WORK,
                      granularity: "segment", structural_value: "300")

      expect(response.body).to include(single.date.to_s)
      expect(response.body).to include(multi.date.to_s)
    end

    it "charts the requested output across sessions sharing a signature" do
      exercise = create(:exercise)
      shape = create(:session_shape, :interval_work)
      session = create(:session, exercise: exercise, session_shape: shape,
                                  weight_kg: 10, work_seconds: 300, date: "2026-07-01")
      create(:session_set, session: session, set_number: 1, reps: 20, duration_seconds: 300)

      get stats_path(exercise_id: exercise.id, shape: SessionShape::INTERVAL_WORK, structural_value: "300:600:5")

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
                      structural_value: "300:600:5", output: "Total output")

      expect(response.body).to include("200")
    end

    it "groups by weight by default and lets a specific weight be locked" do
      exercise = create(:exercise)
      shape = create(:session_shape, :interval_work)
      light = create(:session, exercise: exercise, session_shape: shape,
                                weight_kg: 8, work_seconds: 300, date: "2026-07-01")
      create(:session_set, session: light, set_number: 1, reps: 20, duration_seconds: 300)
      light2 = create(:session, exercise: exercise, session_shape: shape,
                                 weight_kg: 8, work_seconds: 300, date: "2026-07-15")
      create(:session_set, session: light2, set_number: 1, reps: 18, duration_seconds: 300)
      heavy = create(:session, exercise: exercise, session_shape: shape,
                                weight_kg: 10, work_seconds: 300, date: "2026-07-08")
      create(:session_set, session: heavy, set_number: 1, reps: 25, duration_seconds: 300)
      heavy2 = create(:session, exercise: exercise, session_shape: shape,
                                 weight_kg: 10, work_seconds: 300, date: "2026-07-22")
      create(:session_set, session: heavy2, set_number: 1, reps: 22, duration_seconds: 300)

      get stats_path(exercise_id: exercise.id, shape: SessionShape::INTERVAL_WORK, structural_value: "300:600:5")
      chart_script = response.body.scan(/createChart[\s\S]*?;/).select { |s| s.include?("new Chartkick") }.last
      expect(chart_script).to include('"8.0kg"', '"10.0kg"')

      get stats_path(exercise_id: exercise.id, shape: SessionShape::INTERVAL_WORK,
                      structural_value: "300:600:5", weight: "10")
      chart_script = response.body.scan(/createChart[\s\S]*?;/).select { |s| s.include?("new Chartkick") }.last
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
      light = create(:session, exercise: exercise, session_shape: shape, weight_kg: 8, work_seconds: 300,
                                date: "2026-07-01")
      create(:session_set, session: light, set_number: 1, reps: 20, duration_seconds: 300)
      light2 = create(:session, exercise: exercise, session_shape: shape, weight_kg: 8, work_seconds: 300,
                                 date: "2026-07-15")
      create(:session_set, session: light2, set_number: 1, reps: 18, duration_seconds: 300)
      heavy = create(:session, exercise: exercise, session_shape: shape, weight_kg: 10, work_seconds: 300,
                               date: "2026-07-08")
      create(:session_set, session: heavy, set_number: 1, reps: 25, duration_seconds: 300)
      heavy2 = create(:session, exercise: exercise, session_shape: shape, weight_kg: 10, work_seconds: 300,
                                 date: "2026-07-22")
      create(:session_set, session: heavy2, set_number: 1, reps: 22, duration_seconds: 300)

      get stats_path(exercise_id: exercise.id, shape: SessionShape::INTERVAL_WORK, structural_value: "300:600:5")
      chart_script = response.body.scan(/createChart[\s\S]*?;/).select { |s| s.include?("new Chartkick") }.last
      data_json = chart_script[/new Chartkick\["LineChart"\]\("chart-\d+", (.*), \{/, 1]
      data = JSON.parse(data_json)

      expect(data).to all(include("name", "data"))
      expect(data.map { |series| series["name"] }).to contain_exactly("8.0kg", "10.0kg")
    end
  end
end
