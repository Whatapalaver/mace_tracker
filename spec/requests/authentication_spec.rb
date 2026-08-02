require "rails_helper"

RSpec.describe "Owner authentication", type: :request do
  around do |example|
    original_username = ENV["BASIC_AUTH_USER"]
    original_password = ENV["BASIC_AUTH_PASSWORD"]
    example.run
    ENV["BASIC_AUTH_USER"] = original_username
    ENV["BASIC_AUTH_PASSWORD"] = original_password
  end

  context "when no credentials are configured" do
    before do
      ENV["BASIC_AUTH_USER"] = nil
      ENV["BASIC_AUTH_PASSWORD"] = nil
    end

    it "allows unauthenticated access, so local dev/test need no login" do
      get sessions_path

      expect(response).to have_http_status(:ok)
    end
  end

  context "when credentials are configured" do
    before do
      ENV["BASIC_AUTH_USER"] = "owner"
      ENV["BASIC_AUTH_PASSWORD"] = "secret"
    end

    it "rejects requests with no credentials" do
      get sessions_path

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with the wrong credentials" do
      get sessions_path, headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("owner", "wrong") }

      expect(response).to have_http_status(:unauthorized)
    end

    it "allows requests with the correct credentials" do
      get sessions_path, headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("owner", "secret") }

      expect(response).to have_http_status(:ok)
    end

    it "leaves the coach-facing share link accessible with no credentials" do
      share_link = create(:share_link)

      get shared_dashboard_path(share_link.token)

      expect(response).to have_http_status(:ok)
    end
  end
end
