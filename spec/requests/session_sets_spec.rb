require "rails_helper"

RSpec.describe "SessionSets", type: :request do
  describe "GET /session_sets" do
    it "lists sets across all sessions, most recent session date first" do
      older = create(:session, date: Date.new(2026, 7, 1))
      newer = create(:session, date: Date.new(2026, 7, 20))
      create(:session_set, session: older, set_number: 1)
      create(:session_set, session: newer, set_number: 1)

      get session_sets_path

      expect(response).to have_http_status(:ok)
      expect(response.body.index(newer.exercise.display_name)).to be < response.body.index(older.exercise.display_name)
    end

    it "paginates results" do
      session = create(:session)
      30.times { |i| create(:session_set, session: session, set_number: i + 1) }

      get session_sets_path

      expect(response.body).to include("Page 1 of 2")

      get session_sets_path(page: 2)

      expect(response.body).to include("Page 2 of 2")
    end

    it "shows an empty state with no sets logged" do
      get session_sets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No sessions logged yet")
    end
  end

  describe "GET /session_sets/:id/edit" do
    it "renders an editable row" do
      session_set = create(:session_set)

      get edit_session_set_path(session_set)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Save")
    end
  end

  describe "PATCH /session_sets/:id" do
    it "updates the set's fields and the session's date together" do
      session_set = create(:session_set, reps: 20, weight_kg: 10)

      patch session_set_path(session_set), params: {
        date: "2026-07-15",
        session_set: { reps: "25", weight_kg: "12", duration_seconds: "50", rest_seconds_actual: "45" }
      }

      expect(response).to have_http_status(:ok)
      session_set.reload
      expect(session_set.reps).to eq(25)
      expect(session_set.weight_kg).to eq(12)
      expect(session_set.duration_seconds).to eq(50)
      expect(session_set.rest_seconds_actual).to eq(45)
      expect(session_set.session.date).to eq(Date.new(2026, 7, 15))
    end

    it "re-renders the edit row with errors when validation fails" do
      session_set = create(:session_set)

      patch session_set_path(session_set), params: { session_set: { reps: "-1" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("must be greater than 0")
    end
  end

  describe "DELETE /session_sets/:id" do
    it "deletes the set but keeps the session when other sets remain" do
      session = create(:session)
      keep = create(:session_set, session: session, set_number: 1)
      doomed = create(:session_set, session: session, set_number: 2)

      expect { delete session_set_path(doomed) }.to change(SessionSet, :count).by(-1)

      expect(Session.exists?(session.id)).to be true
      expect(SessionSet.exists?(keep.id)).to be true
      expect(response).to redirect_to(session_sets_path)
    end

    it "deletes the whole session when its last set is removed" do
      session = create(:session)
      only_set = create(:session_set, session: session, set_number: 1)

      expect { delete session_set_path(only_set) }.to change(Session, :count).by(-1)
    end
  end
end
