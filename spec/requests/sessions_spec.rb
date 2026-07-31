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

    it "shows a banner when starting from a benchmark preset" do
      preset = create(:benchmark_preset, name: "Monthly 3x5")

      get new_session_path(benchmark_preset_id: preset.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Starting from benchmark preset: Monthly 3x5")
    end

    it "pre-fills the formula field by rendering the preset's plan back into notation" do
      preset = create(:benchmark_preset, planned_weight_kg: 10, planned_work_seconds: 300,
                                          planned_rest_seconds: 300, planned_sets: 5)

      get new_session_path(benchmark_preset_id: preset.id)

      expect(response.body).to include("5(5mw+5mr)@10kg")
    end

    it "lists existing presets in a picker" do
      create(:benchmark_preset, name: "Monthly 3x5")

      get new_session_path

      expect(response.body).to include("Start from a saved preset")
      expect(response.body).to include("Monthly 3x5")
    end
  end

  describe "POST /sessions" do
    let(:exercise) { create(:exercise) }
    let(:interval_work_shape) { create(:session_shape, :interval_work) }
    let(:fixed_reps_for_time_shape) { create(:session_shape, :fixed_reps_for_time) }
    let(:emom_shape) { create(:session_shape, :emom) }

    context "interval_work" do
      it "parses the formula and renders a review step without saving yet" do
        expect {
          post sessions_path, params: { session: {
            date: "2026-07-30", exercise_id: exercise.id, session_shape_id: interval_work_shape.id,
            formula: "5(5mw+5mr)@10kg"
          } }
        }.not_to change(Session, :count)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Set 1", "300s")
      end

      it "creates the session and its sets once the review is confirmed" do
        params = {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: interval_work_shape.id,
          planned_weight_kg: "10", planned_work_seconds: "300", planned_rest_seconds: "300", planned_sets: "3",
          session_sets_attributes: {
            "0" => { set_number: "1", duration_seconds: "300", reps: "20" },
            "1" => { set_number: "2", duration_seconds: "300", reps: "19" },
            "2" => { set_number: "3", duration_seconds: "300", reps: "18" }
          }
        }

        expect { post sessions_path, params: { session: params } }.to change(Session, :count).by(1)

        session = Session.last
        expect(session.session_sets.count).to eq(3)
        expect(session.session_sets.order(:set_number).pluck(:reps)).to eq([ 20, 19, 18 ])
        expect(response).to redirect_to(session_path(session))
      end

      it "re-renders the form with an error for an invalid formula" do
        post sessions_path, params: { session: {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: interval_work_shape.id,
          formula: "not a formula"
        } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Log Session")
      end

      it "re-renders the form when the formula is missing its weight suffix" do
        post sessions_path, params: { session: {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: interval_work_shape.id,
          formula: "5(5mw+5mr)"
        } }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "suggests a matching preset on the review step without attaching it automatically" do
        preset = create(:benchmark_preset, name: "5 x 5", exercise: exercise, session_shape: interval_work_shape,
                                            planned_weight_kg: 10, planned_work_seconds: 300,
                                            planned_rest_seconds: 300, planned_sets: 5)

        post sessions_path, params: { session: {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: interval_work_shape.id,
          formula: "5(5mw+5mr)@10kg"
        } }

        expect(response.body).to include("Matches preset")
        expect(response.body).to include("5 x 5")
        expect(response.body).to include(%(name="session[benchmark_preset_id]" id="session_benchmark_preset_id" value="#{preset.id}"))
      end

      it "does not suggest a preset when nothing matches" do
        create(:benchmark_preset, exercise: exercise, session_shape: interval_work_shape,
                                   planned_weight_kg: 12, planned_work_seconds: 300,
                                   planned_rest_seconds: 300, planned_sets: 5)

        post sessions_path, params: { session: {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: interval_work_shape.id,
          formula: "5(5mw+5mr)@10kg"
        } }

        expect(response.body).not_to include("Matches preset")
      end

      it "attaches the suggested preset when the checkbox is checked on confirm" do
        preset = create(:benchmark_preset, exercise: exercise, session_shape: interval_work_shape,
                                            planned_weight_kg: 10, planned_work_seconds: 300,
                                            planned_rest_seconds: 300, planned_sets: 3)

        params = {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: interval_work_shape.id,
          benchmark_preset_id: preset.id,
          planned_weight_kg: "10", planned_work_seconds: "300", planned_rest_seconds: "300", planned_sets: "3",
          session_sets_attributes: {
            "0" => { set_number: "1", duration_seconds: "300", reps: "20" },
            "1" => { set_number: "2", duration_seconds: "300", reps: "19" },
            "2" => { set_number: "3", duration_seconds: "300", reps: "18" }
          }
        }

        post sessions_path, params: { session: params }

        session = Session.last
        expect(session.benchmark_preset).to eq(preset)
        expect(session.is_benchmark).to eq(true)
      end
    end

    context "fixed_reps_for_time" do
      it "parses the formula and renders a review step with reps pre-filled" do
        post sessions_path, params: { session: {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: fixed_reps_for_time_shape.id,
          formula: "5(108@10kg)"
        } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('value="108"')
      end

      it "suggests a matching preset keyed on weight and target_reps" do
        create(:benchmark_preset, :fixed_reps_for_time, name: "Time to 108", exercise: exercise,
                                                          session_shape: fixed_reps_for_time_shape,
                                                          planned_weight_kg: 10, target_reps: 108)

        post sessions_path, params: { session: {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: fixed_reps_for_time_shape.id,
          formula: "5(108@10kg)"
        } }

        expect(response.body).to include("Matches preset", "Time to 108")
      end

      it "creates the session and its sets once the review is confirmed" do
        params = {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: fixed_reps_for_time_shape.id,
          planned_weight_kg: "10", target_reps: "108",
          session_sets_attributes: {
            "0" => { set_number: "1", reps: "108", duration_seconds: "240" },
            "1" => { set_number: "2", reps: "108", duration_seconds: "235" }
          }
        }

        expect { post sessions_path, params: { session: params } }.to change(Session, :count).by(1)

        session = Session.last
        expect(session.session_sets.order(:set_number).pluck(:reps, :duration_seconds)).to eq(
          [ [ 108, 240 ], [ 108, 235 ] ]
        )
      end
    end

    context "emom" do
      it "creates the session and its sets immediately, with no review step" do
        params = {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: emom_shape.id,
          formula: "10(20@10kg)"
        }

        expect { post sessions_path, params: { session: params } }.to change(Session, :count).by(1)

        session = Session.last
        expect(session.target_reps_per_minute).to eq(20)
        expect(session.session_sets.count).to eq(10)
        expect(session.session_sets.pluck(:reps).uniq).to eq([ 20 ])
        expect(response).to redirect_to(session_path(session))
      end

      it "attaches a benchmark_preset and marks the session as a benchmark" do
        preset = create(:benchmark_preset, :emom, exercise: exercise)

        post sessions_path, params: { session: {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: preset.session_shape_id,
          formula: "10(20@10kg)", benchmark_preset_id: preset.id
        } }

        session = Session.last
        expect(session.benchmark_preset).to eq(preset)
        expect(session.is_benchmark).to eq(true)
      end
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

    it "shows a benchmark badge for benchmark sessions" do
      session = create(:session, is_benchmark: true)

      get session_path(session)

      expect(response.body).to include("Benchmark")
    end

    it "links to the stats page to view progression" do
      session = create(:session)

      get session_path(session)

      expect(response.body).to include("View progression")
    end
  end
end
