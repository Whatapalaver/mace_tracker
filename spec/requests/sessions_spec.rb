require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /sessions/new" do
    it "renders the form when exercises exist" do
      create(:exercise)

      get new_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Shape", "Reps")
      expect(response.body).to include("Fixed reps for time", "EMOM")
    end

    it "does not show interval_work/sets_and_reps as explicit shape choices — they're inferred" do
      create(:exercise)

      get new_session_path

      expect(response.body).not_to include(">Interval work<")
      expect(response.body).not_to include(">Sets &amp; reps<")
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

    it "pre-fills the signature and weight fields by rendering the preset's plan back into notation" do
      preset = create(:benchmark_preset, weight_kg: 10, work_seconds: 300,
                                          rest_seconds: 300, sets_count: 5)

      get new_session_path(benchmark_preset_id: preset.id)

      expect(response.body).to include(%(value="5(5mw+5mr)" name="session[signature]"))
      expect(response.body).to include(%(value="10.0" name="session[weight_kg]"))
    end

    it "pre-fills the legacy formula field and opens the advanced section for a fixed_reps_for_time/emom preset" do
      preset = create(:benchmark_preset, :emom, weight_kg: 10, reps_per_minute: 20)

      get new_session_path(benchmark_preset_id: preset.id)

      expect(response.body).to include("1(20@10kg)")
      expect(response.body).to match(/<details[^>]* open[^>]*>/)
    end

    it "lists existing presets in a picker" do
      create(:benchmark_preset, name: "Monthly 3x5")

      get new_session_path

      expect(response.body).to include("Start from a saved preset")
      expect(response.body).to include("Monthly 3x5")
    end

    it "offers a tool picker once at least one tool is registered" do
      create(:exercise)
      create(:tool, name: "Eryx Adjustable")

      get new_session_path

      expect(response.body).to include("Tool (optional)")
      expect(response.body).to include("Eryx Adjustable")
    end

    it "hides the tool picker until a tool is registered" do
      create(:exercise)

      get new_session_path

      expect(response.body).not_to include("Tool (optional)")
    end
  end

  describe "POST /sessions" do
    let(:exercise) { create(:exercise) }
    let(:fixed_reps_for_time_shape) { create(:session_shape, :fixed_reps_for_time) }
    let(:emom_shape) { create(:session_shape, :emom) }

    # The primary one-step flow: no session_shape_id, no formula — shape is inferred from the
    # signature text and the session saves immediately with no review step.
    context "interval_work (inferred from signature)" do
      it "creates the session and its sets immediately from a signature and reps list" do
        params = { date: "2026-07-30", exercise_id: exercise.id, signature: "3(5mw+5mr)",
                   weight_kg: "10", reps_list: "20, 19, 18" }

        expect { post sessions_path, params: { session: params } }.to change(Session, :count).by(1)

        session = Session.last
        expect(session.session_shape.name).to eq(SessionShape::INTERVAL_WORK)
        expect(session.work_seconds).to eq(300)
        expect(session.rest_seconds).to eq(300)
        expect(session.sets_count).to eq(3)
        expect(session.session_sets.order(:set_number).pluck(:reps)).to eq([ 20, 19, 18 ])
        expect(response).to redirect_to(session_path(session))
      end

      it "infers interval_work from a bare single-set signature like 5mw, with no wrapping N(...)" do
        params = { date: "2026-07-30", exercise_id: exercise.id, signature: "5mw",
                   weight_kg: "10", reps_list: "200" }

        post sessions_path, params: { session: params }

        session = Session.last
        expect(session.session_shape.name).to eq(SessionShape::INTERVAL_WORK)
        expect(session.work_seconds).to eq(300)
        expect(session.rest_seconds).to eq(0)
        expect(session.sets_count).to eq(1)
        expect(session.session_sets.sole.reps).to eq(200)
      end

      it "saves the chosen tool alongside the session" do
        tool = create(:tool, equipment: exercise.equipment)
        params = { date: "2026-07-30", exercise_id: exercise.id, tool_id: tool.id, signature: "5mw",
                   weight_kg: "10", reps_list: "20" }

        post sessions_path, params: { session: params }

        expect(Session.last.tool).to eq(tool)
      end

      it "rejects a tool that belongs to different equipment than the exercise" do
        mismatched_tool = create(:tool, equipment: create(:equipment, name: "Kettlebell"))
        params = { date: "2026-07-30", exercise_id: exercise.id, tool_id: mismatched_tool.id,
                   signature: "5mw", weight_kg: "10", reps_list: "20" }

        expect { post sessions_path, params: { session: params } }.not_to change(Session, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "re-renders the form with an error for invalid signature notation" do
        params = { date: "2026-07-30", exercise_id: exercise.id, signature: "5(5mw",
                   weight_kg: "10", reps_list: "20" }

        post sessions_path, params: { session: params }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Log Session")
      end

      it "shows a clear error when the signature is left blank, not the interval parser's internal wording" do
        params = { date: "2026-07-30", exercise_id: exercise.id, signature: "",
                   weight_kg: "10", reps_list: "20" }

        post sessions_path, params: { session: params }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Signature can&#39;t be blank")
        expect(response.body).not_to include("Input cannot be empty")
      end

      it "rejects a reps list whose length disagrees with the signature's implied set count" do
        params = { date: "2026-07-30", exercise_id: exercise.id, signature: "3(5mw+5mr)",
                   weight_kg: "10", reps_list: "20, 19" }

        expect { post sessions_path, params: { session: params } }.not_to change(Session, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Signature implies 3 sets but 2 rep values were given")
      end

      it "repeats a single reps value across every set of a many-set interval (Viking Warrior style)" do
        params = { date: "2026-07-30", exercise_id: exercise.id, signature: "50(15w+15r)",
                   weight_kg: "10", reps_list: "7" }

        expect { post sessions_path, params: { session: params } }.to change(Session, :count).by(1)

        session = Session.last
        expect(session.sets_count).to eq(50)
        expect(session.session_sets.count).to eq(50)
        expect(session.session_sets.pluck(:reps).uniq).to eq([ 7 ])
      end
    end

    context "sets_and_reps (inferred fallback for a bare number)" do
      it "creates the session and its sets immediately from a bare reps signature and reps list" do
        params = { date: "2026-07-30", exercise_id: exercise.id, signature: "24",
                   weight_kg: "10", reps_list: "24, 24, 22, 20" }

        expect { post sessions_path, params: { session: params } }.to change(Session, :count).by(1)

        session = Session.last
        expect(session.session_shape.name).to eq(SessionShape::SETS_AND_REPS)
        expect(session.reps).to eq(24)
        expect(session.session_sets.order(:set_number).pluck(:reps)).to eq([ 24, 24, 22, 20 ])
        expect(session.session_sets.pluck(:duration_seconds).uniq).to eq([ nil ])
      end

      it "defaults Reps to the signature's own number for a single-set session when Reps is left blank" do
        params = { date: "2026-07-30", exercise_id: exercise.id, signature: "200",
                   weight_kg: "10", reps_list: "" }

        expect { post sessions_path, params: { session: params } }.to change(Session, :count).by(1)

        session = Session.last
        expect(session.reps).to eq(200)
        expect(session.session_sets.sole.reps).to eq(200)
      end

      it "still uses an explicitly given Reps value over the signature's number" do
        params = { date: "2026-07-30", exercise_id: exercise.id, signature: "24",
                   weight_kg: "10", reps_list: "20" }

        post sessions_path, params: { session: params }

        session = Session.last
        expect(session.reps).to eq(24)
        expect(session.session_sets.sole.reps).to eq(20)
      end

      it "supports a per-set weight override in the reps list" do
        params = { date: "2026-07-30", exercise_id: exercise.id, signature: "100",
                   weight_kg: "6", reps_list: "100@6, 100@6, 50@8" }

        post sessions_path, params: { session: params }

        session = Session.last
        expect(session.session_sets.order(:set_number).map(&:effective_weight_kg)).to eq([ 6.0, 6.0, 8.0 ])
      end

      it "allows leaving the session-level weight blank when every set has its own override" do
        params = { date: "2026-07-30", exercise_id: exercise.id, signature: "20",
                   weight_kg: "", reps_list: "20@10, 20@12, 25@14, 15@16, 20@15" }

        expect { post sessions_path, params: { session: params } }.to change(Session, :count).by(1)

        session = Session.last
        expect(session.session_sets.order(:set_number).map(&:effective_weight_kg)).to eq(
          [ 10.0, 12.0, 14.0, 16.0, 15.0 ]
        )
      end

      it "rejects a blank session-level weight when at least one set has no override" do
        params = { date: "2026-07-30", exercise_id: exercise.id, signature: "20",
                   weight_kg: "", reps_list: "20@10, 20" }

        expect { post sessions_path, params: { session: params } }.not_to change(Session, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body.scan("Weight kg can&#39;t be blank").size).to eq(1)
      end

      it "re-renders the form with an error when the signature is neither notation nor a number" do
        params = { date: "2026-07-30", exercise_id: exercise.id, signature: "not anything",
                   weight_kg: "10", reps_list: "20" }

        post sessions_path, params: { session: params }

        expect(response).to have_http_status(:unprocessable_content)
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

    it "shows the session's shape" do
      create(:session, :emom)

      get sessions_path

      expect(response.body).to include("EMOM")
    end

    it "shows a session's notes" do
      create(:session, notes: "Felt strong today")

      get sessions_path

      expect(response.body).to include("Felt strong today")
    end

    it "paginates results" do
      60.times { |i| create(:session, date: Date.new(2026, 1, 1) + i) }

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

    it "filters to a chosen year" do
      create(:session, date: Date.new(2025, 6, 15))
      create(:session, date: Date.new(2026, 3, 10))

      get sessions_path(year: 2026)

      expect(response.body).to include("10 Mar")
      expect(response.body).not_to include("15 Jun")
    end

    it "filters to a chosen year and month" do
      create(:session, date: Date.new(2026, 3, 10))
      create(:session, date: Date.new(2026, 7, 1))

      get sessions_path(year: 2026, month: 7)

      expect(response.body).to include("01 Jul")
      expect(response.body).not_to include("10 Mar")
    end

    it "ignores a month filter without a year" do
      create(:session, date: Date.new(2026, 3, 10))

      get sessions_path(month: 3)

      expect(response.body).to include("10 Mar")
    end

    it "filters to zero results for a year with no sessions, rather than ignoring the filter" do
      create(:session, date: Date.new(2026, 3, 10))

      get sessions_path(year: 1999)

      expect(response.body).to include("No sessions match the selected filters")
      expect(response.body).not_to include("10 Mar")
    end

    it "ignores an out-of-range month" do
      create(:session, date: Date.new(2026, 3, 10))

      get sessions_path(year: 2026, month: 13)

      expect(response.body).to include("10 Mar")
    end

    it "shows a distinct message when filters exclude everything but sessions exist" do
      create(:session, date: Date.new(2026, 3, 10))

      get sessions_path(year: 2026, month: 1)

      expect(response.body).to include("No sessions match the selected filters")
      expect(response.body).not_to include("No sessions logged yet")
    end

    it "does not show the month filter until a year is chosen" do
      create(:session, date: Date.new(2026, 3, 10))

      get sessions_path

      expect(response.body).not_to include(">Month<")
    end

    it "filters to a chosen exercise" do
      mace_360 = create(:exercise, name: "360", equipment: create(:equipment, name: "Mace"))
      snatch = create(:exercise, name: "Snatch", equipment: create(:equipment, name: "Kettlebell"))
      keep = create(:session, date: Date.new(2026, 3, 10), exercise: mace_360)
      create(:session, date: Date.new(2026, 3, 11), exercise: snatch)

      get sessions_path(exercise_id: keep.exercise_id)

      expect(response.body).to include("10 Mar")
      expect(response.body).not_to include("11 Mar")
    end

    it "filters to a chosen equipment, across all its exercises" do
      mace = create(:equipment, name: "Mace")
      kettlebell = create(:equipment, name: "Kettlebell")
      mace_360 = create(:exercise, name: "360", equipment: mace)
      mace_10_2 = create(:exercise, name: "10-2", equipment: mace)
      snatch = create(:exercise, name: "Snatch", equipment: kettlebell)
      create(:session, date: Date.new(2026, 3, 10), exercise: mace_360)
      create(:session, date: Date.new(2026, 3, 11), exercise: mace_10_2)
      create(:session, date: Date.new(2026, 3, 12), exercise: snatch)

      get sessions_path(equipment_id: mace.id)

      expect(response.body).to include("10 Mar")
      expect(response.body).to include("11 Mar")
      expect(response.body).not_to include("12 Mar")
    end

    it "narrows the exercise dropdown to the chosen equipment" do
      mace = create(:equipment, name: "Mace")
      kettlebell = create(:equipment, name: "Kettlebell")
      create(:exercise, name: "360", equipment: mace)
      create(:exercise, name: "Snatch", equipment: kettlebell)
      create(:session, date: Date.new(2026, 3, 10))

      get sessions_path(equipment_id: mace.id)

      expect(response.body).to include("Mace 360")
      expect(response.body).not_to include("Kettlebell Snatch")
    end

    it "ignores an exercise filter that doesn't belong to the chosen equipment" do
      mace = create(:equipment, name: "Mace")
      kettlebell = create(:equipment, name: "Kettlebell")
      mace_360 = create(:exercise, name: "360", equipment: mace)
      snatch = create(:exercise, name: "Snatch", equipment: kettlebell)
      create(:session, date: Date.new(2026, 3, 10), exercise: mace_360)

      get sessions_path(equipment_id: mace.id, exercise_id: snatch.id)

      expect(response.body).to include("10 Mar")
    end

    it "filters to a chosen tool via the grouped equipment/tool select" do
      mace = create(:equipment, name: "Mace")
      exercise = create(:exercise, equipment: mace)
      eryx = create(:tool, name: "Eryx Adjustable", equipment: mace)
      wrecking_ball = create(:tool, name: "Wrecking Ball", equipment: mace)
      create(:session, date: Date.new(2026, 3, 10), exercise: exercise, tool: eryx)
      create(:session, date: Date.new(2026, 3, 11), exercise: exercise, tool: wrecking_ball)

      get sessions_path(equipment_id: "tool-#{eryx.id}")

      expect(response.body).to include("10 Mar")
      expect(response.body).not_to include("11 Mar")
    end

    it "shows the tool grouped under its equipment in the filter select" do
      mace = create(:equipment, name: "Mace")
      create(:tool, name: "Eryx Adjustable", equipment: mace)
      create(:session, date: Date.new(2026, 3, 10))

      get sessions_path

      expect(response.body).to include("All Mace")
      expect(response.body).to include("Eryx Adjustable")
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

    it "allows leaving the session-level weight blank when every set has its own override" do
      session = create(:session, work_seconds: 300, rest_seconds: 0, sets_count: 2)
      create(:session_set, session: session, set_number: 1, reps: 20)
      create(:session_set, session: session, set_number: 2, reps: 20)

      patch session_path(session), params: {
        session: { date: session.date.to_s, signature: session.weight_agnostic_signature,
                   weight_kg: "", reps_list: "20@10, 25@12" }
      }

      expect(response).to have_http_status(:ok)
      session.reload
      expect(session.session_sets.order(:set_number).map(&:effective_weight_kg)).to eq([ 10.0, 12.0 ])
    end

    it "defaults Reps to the signature's own number for sets_and_reps when Reps is left blank" do
      session = create(:session, :sets_and_reps, reps: 24)
      create(:session_set, session: session, set_number: 1, reps: 24)

      patch session_path(session), params: {
        session: { date: session.date.to_s, signature: "200", weight_kg: session.weight_kg, reps_list: "" }
      }

      expect(response).to have_http_status(:ok)
      session.reload
      expect(session.reps).to eq(200)
      expect(session.session_sets.sole.reps).to eq(200)
    end

    it "updates the session's tool" do
      session = create(:session, work_seconds: 300, rest_seconds: 0, sets_count: 1)
      create(:session_set, session: session, set_number: 1, reps: 20)
      tool = create(:tool, equipment: session.exercise.equipment)

      patch session_path(session), params: {
        session: { date: session.date.to_s, signature: session.weight_agnostic_signature,
                   weight_kg: session.weight_kg, reps_list: "20", tool_id: tool.id }
      }

      expect(response).to have_http_status(:ok)
      expect(session.reload.tool).to eq(tool)
    end

    it "rejects a tool that doesn't match the session's exercise equipment" do
      session = create(:session, work_seconds: 300, rest_seconds: 0, sets_count: 1)
      create(:session_set, session: session, set_number: 1, reps: 20)
      mismatched_tool = create(:tool, equipment: create(:equipment, name: "Kettlebell"))

      patch session_path(session), params: {
        session: { date: session.date.to_s, signature: session.weight_agnostic_signature,
                   weight_kg: session.weight_kg, reps_list: "20", tool_id: mismatched_tool.id }
      }

      expect(response).to have_http_status(:unprocessable_content)
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

    it "repeats a single reps value across every set when editing a many-set interval" do
      session = create(:session, work_seconds: 15, rest_seconds: 15, sets_count: 50)
      create(:session_set, session: session, set_number: 1, reps: 20)

      patch session_path(session), params: {
        session: { signature: "50(15w+15r)", weight_kg: session.weight_kg, reps_list: "7" }
      }

      expect(response).to have_http_status(:ok)
      session.reload
      expect(session.session_sets.count).to eq(50)
      expect(session.session_sets.pluck(:reps).uniq).to eq([ 7 ])
    end

    it "rejects invalid signature notation" do
      session = create(:session)
      create(:session_set, session: session, set_number: 1, reps: 20)

      patch session_path(session), params: {
        session: { signature: "not a formula", weight_kg: session.weight_kg, reps_list: "20" }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "converts a sets_and_reps session to interval_work, parsing the signature under the new shape" do
      sets_and_reps_shape = create(:session_shape, :sets_and_reps)
      interval_work_shape = create(:session_shape, :interval_work)
      session = create(:session, session_shape: sets_and_reps_shape, weight_kg: 10, reps: 1101, work_seconds: nil,
                                  rest_seconds: nil, sets_count: nil)
      create(:session_set, session: session, set_number: 1, reps: 1101)

      patch session_path(session), params: {
        session: { date: session.date.to_s, session_shape_id: interval_work_shape.id,
                   signature: "30mw", weight_kg: "10", reps_list: "1101" }
      }

      expect(response).to have_http_status(:ok)
      session.reload
      expect(session.session_shape).to eq(interval_work_shape)
      expect(session.work_seconds).to eq(1800)
      expect(session.rest_seconds).to eq(0)
      expect(session.sets_count).to eq(1)
      expect(session.reps).to be_nil
      expect(session.session_sets.sole.reps).to eq(1101)
    end

    it "converts an interval_work session to sets_and_reps, clearing the old interval fields" do
      interval_work_shape = create(:session_shape, :interval_work)
      sets_and_reps_shape = create(:session_shape, :sets_and_reps)
      session = create(:session, session_shape: interval_work_shape, weight_kg: 10,
                                  work_seconds: 300, rest_seconds: 300, sets_count: 3)
      create(:session_set, session: session, set_number: 1, reps: 20)
      create(:session_set, session: session, set_number: 2, reps: 19)
      create(:session_set, session: session, set_number: 3, reps: 18)

      patch session_path(session), params: {
        session: { date: session.date.to_s, session_shape_id: sets_and_reps_shape.id,
                   signature: "20", weight_kg: "10", reps_list: "20" }
      }

      expect(response).to have_http_status(:ok)
      session.reload
      expect(session.session_shape).to eq(sets_and_reps_shape)
      expect(session.reps).to eq(20)
      expect(session.work_seconds).to be_nil
      expect(session.rest_seconds).to be_nil
      expect(session.sets_count).to be_nil
      expect(session.session_sets.sole.reps).to eq(20)
    end

    it "rejects a reps list that disagrees with the new shape's signature when switching shapes" do
      sets_and_reps_shape = create(:session_shape, :sets_and_reps)
      interval_work_shape = create(:session_shape, :interval_work)
      session = create(:session, session_shape: sets_and_reps_shape, weight_kg: 10, reps: 1101)
      create(:session_set, session: session, set_number: 1, reps: 1101)

      # Two values against an implied 3 sets — genuinely mismatched, not the "one value repeats
      # to fill every set" shorthand (which only kicks in for a single reps entry).
      patch session_path(session), params: {
        session: { date: session.date.to_s, session_shape_id: interval_work_shape.id,
                   signature: "3(5mw+5mr)", weight_kg: "10", reps_list: "1101, 1100" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Signature implies 3 sets but 2 rep values were given")
      expect(session.reload.session_shape).to eq(sets_and_reps_shape)
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
