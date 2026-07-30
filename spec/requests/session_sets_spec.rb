require "rails_helper"

RSpec.describe "SessionSets", type: :request do
  let(:session) { create(:session) }

  describe "GET /sessions/:session_id/session_sets/new" do
    it "renders the form" do
      get new_session_session_set_path(session)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /sessions/:session_id/session_sets" do
    it "creates a set, auto-assigning the next set_number, and redirects to the session" do
      create(:session_set, session: session, set_number: 1)

      expect {
        post session_session_sets_path(session), params: { session_set: { reps: 20, weight_kg: "", duration_seconds: 280 } }
      }.to change(session.session_sets, :count).by(1)

      expect(session.session_sets.order(:set_number).last.set_number).to eq(2)
      expect(response).to redirect_to(session_path(session))
    end

    it "re-renders the form with errors when invalid" do
      expect {
        post session_session_sets_path(session), params: { session_set: { reps: -1 } }
      }.not_to change(SessionSet, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
