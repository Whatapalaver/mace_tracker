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
      expect(response.body).to include("Starting from benchmark preset:", "Monthly 3x5")
    end

    it "pre-fills the formula field by rendering the preset's plan back into notation" do
      preset = create(:benchmark_preset, weight_kg: 10, work_seconds: 300,
                                          rest_seconds: 300, sets_count: 5)

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
          weight_kg: "10", work_seconds: "300", rest_seconds: "300", sets_count: "3",
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
                                            weight_kg: 10, work_seconds: 300,
                                            rest_seconds: 300, sets_count: 5)

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
                                   weight_kg: 12, work_seconds: 300,
                                   rest_seconds: 300, sets_count: 5)

        post sessions_path, params: { session: {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: interval_work_shape.id,
          formula: "5(5mw+5mr)@10kg"
        } }

        expect(response.body).not_to include("Matches preset")
      end

      it "attaches the suggested preset when the checkbox is checked on confirm" do
        preset = create(:benchmark_preset, exercise: exercise, session_shape: interval_work_shape,
                                            weight_kg: 10, work_seconds: 300,
                                            rest_seconds: 300, sets_count: 3)

        params = {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: interval_work_shape.id,
          benchmark_preset_id: preset.id,
          weight_kg: "10", work_seconds: "300", rest_seconds: "300", sets_count: "3",
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

      it "suggests a matching preset keyed on weight and reps" do
        create(:benchmark_preset, :fixed_reps_for_time, name: "Time to 108", exercise: exercise,
                                                          session_shape: fixed_reps_for_time_shape,
                                                          weight_kg: 10, reps: 108)

        post sessions_path, params: { session: {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: fixed_reps_for_time_shape.id,
          formula: "5(108@10kg)"
        } }

        expect(response.body).to include("Matches preset", "Time to 108")
      end

      it "creates the session and its sets once the review is confirmed" do
        params = {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: fixed_reps_for_time_shape.id,
          weight_kg: "10", reps: "108",
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
        expect(session.reps_per_minute).to eq(20)
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

    context "sets_and_reps" do
      let(:sets_and_reps_shape) { create(:session_shape, :sets_and_reps) }

      it "parses the formula and renders a review step with reps pre-filled, no duration field" do
        post sessions_path, params: { session: {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: sets_and_reps_shape.id,
          formula: "4(24@10kg)"
        } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('value="24"')
        expect(response.body).not_to include('placeholder="seconds"')
        expect(response.body).not_to include("session_sets_attributes][0][duration_seconds]")
      end

      it "creates the session and its sets once the review is confirmed" do
        params = {
          date: "2026-07-30", exercise_id: exercise.id, session_shape_id: sets_and_reps_shape.id,
          weight_kg: "10", reps: "24",
          session_sets_attributes: {
            "0" => { set_number: "1", reps: "24" },
            "1" => { set_number: "2", reps: "24" },
            "2" => { set_number: "3", reps: "22" },
            "3" => { set_number: "4", reps: "20" }
          }
        }

        expect { post sessions_path, params: { session: params } }.to change(Session, :count).by(1)

        session = Session.last
        expect(session.session_sets.order(:set_number).pluck(:reps)).to eq([ 24, 24, 22, 20 ])
        expect(session.session_sets.pluck(:duration_seconds).uniq).to eq([ nil ])
      end
    end
  end

  describe "GET /sessions/:id" do
    it "shows session details and computed outputs" do
      session = create(:session, weight_kg: 10, work_seconds: 300, rest_seconds: 600)
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

  describe "DELETE /sessions/:id" do
    it "deletes the session and all its sets" do
      session = create(:session)
      create(:session_set, session: session, set_number: 1)

      expect { delete session_path(session) }.to change(Session, :count).by(-1)
        .and change(SessionSet, :count).by(-1)

      expect(response).to redirect_to(sessions_path)
    end
  end

  describe "GET /sessions" do
    it "lists sessions, most recent date first" do
      older = create(:session, date: Date.new(2026, 7, 1))
      newer = create(:session, date: Date.new(2026, 7, 20))
      create(:session_set, session: older, set_number: 1, reps: 20)
      create(:session_set, session: newer, set_number: 1, reps: 25)

      get sessions_path

      expect(response).to have_http_status(:ok)
      expect(response.body.index(newer.date.to_fs(:short))).to be < response.body.index(older.date.to_fs(:short))
    end

    it "shows the weight-agnostic signature, weight, and reps list per session" do
      session = create(:session, weight_kg: 10, work_seconds: 300, rest_seconds: 300, sets_count: 3)
      create(:session_set, session: session, set_number: 1, reps: 20)
      create(:session_set, session: session, set_number: 2, reps: 19)
      create(:session_set, session: session, set_number: 3, reps: 18)

      get sessions_path

      expect(response.body).to include("3(5mw+5mr)")
      expect(response.body).to include("20, 19, 18")
      expect(response.body).not_to include("3(5mw+5mr)@10kg")
    end

    it "shows a session's notes" do
      create(:session, notes: "Felt strong today")

      get sessions_path

      expect(response.body).to include("Felt strong today")
    end

    it "paginates results" do
      30.times { |i| create(:session, date: Date.new(2026, 1, 1) + i) }

      get sessions_path

      expect(response.body).to include("Page 1 of 2")

      get sessions_path(page: 2)

      expect(response.body).to include("Page 2 of 2")
    end

    it "shows an empty state with no sessions logged" do
      get sessions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No sessions logged yet")
    end
  end

  describe "GET /sessions/:id/edit" do
    it "renders an editable row pre-filled with the current signature and reps" do
      session = create(:session, work_seconds: 300, rest_seconds: 300, sets_count: 3)
      create(:session_set, session: session, set_number: 1, reps: 20)
      create(:session_set, session: session, set_number: 2, reps: 19)
      create(:session_set, session: session, set_number: 3, reps: 18)

      get edit_session_path(session)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="3(5mw+5mr)"')
      expect(response.body).to include('value="20, 19, 18"')
    end

    it "pre-fills the notes field" do
      session = create(:session, notes: "Felt strong today")

      get edit_session_path(session)

      expect(response.body).to include('value="Felt strong today"')
    end
  end

  describe "PATCH /sessions/:id" do
    it "re-parses the signature and rebuilds sets from the reps list" do
      session = create(:session, work_seconds: 300, rest_seconds: 300, sets_count: 3, weight_kg: 10)
      create(:session_set, session: session, set_number: 1, reps: 20)
      create(:session_set, session: session, set_number: 2, reps: 19)
      create(:session_set, session: session, set_number: 3, reps: 18)

      patch session_path(session), params: {
        session: { date: session.date.to_s, signature: "5(5mw+5mr)", weight_kg: "12",
                   reps_list: "25, 24, 23, 22, 21", is_benchmark: "1" }
      }

      expect(response).to have_http_status(:ok)
      session.reload
      expect(session.work_seconds).to eq(300)
      expect(session.rest_seconds).to eq(300)
      expect(session.sets_count).to eq(5)
      expect(session.weight_kg).to eq(12)
      expect(session.is_benchmark).to eq(true)
      expect(session.session_sets.order(:set_number).pluck(:reps)).to eq([ 25, 24, 23, 22, 21 ])
    end

    it "updates the session's notes" do
      session = create(:session, work_seconds: 300, rest_seconds: 0, sets_count: 1, notes: "Old note")
      create(:session_set, session: session, set_number: 1, reps: 20)

      patch session_path(session), params: {
        session: { date: session.date.to_s, signature: session.weight_agnostic_signature,
                   weight_kg: session.weight_kg, reps_list: "20", notes: "New note" }
      }

      expect(response).to have_http_status(:ok)
      expect(session.reload.notes).to eq("New note")
    end

    it "updates the session's date" do
      session = create(:session, date: Date.new(2026, 1, 1), work_seconds: 300, rest_seconds: 0, sets_count: 1)
      create(:session_set, session: session, set_number: 1, reps: 20)

      patch session_path(session), params: {
        session: { date: "2026-06-15", signature: session.weight_agnostic_signature,
                   weight_kg: session.weight_kg, reps_list: "20" }
      }

      expect(session.reload.date).to eq(Date.new(2026, 6, 15))
    end

    it "rejects a reps list whose length disagrees with the signature's set count" do
      session = create(:session, work_seconds: 300, rest_seconds: 300, sets_count: 3)
      create(:session_set, session: session, set_number: 1, reps: 20)
      create(:session_set, session: session, set_number: 2, reps: 19)
      create(:session_set, session: session, set_number: 3, reps: 18)

      patch session_path(session), params: {
        session: { signature: "3(5mw+5mr)", weight_kg: session.weight_kg, reps_list: "20, 19" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Signature implies 3 sets but 2 rep values were given")
      expect(session.reload.session_sets.count).to eq(3)
    end

    it "rejects invalid signature notation" do
      session = create(:session)
      create(:session_set, session: session, set_number: 1, reps: 20)

      patch session_path(session), params: {
        session: { signature: "not a formula", weight_kg: session.weight_kg, reps_list: "20" }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /sessions/:id/row" do
    it "renders just the display row" do
      session = create(:session)
      create(:session_set, session: session, set_number: 1, reps: 20)

      get row_session_path(session)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit")
    end
  end
end
