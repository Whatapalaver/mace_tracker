require "rails_helper"

RSpec.describe "PWA", type: :request do
  it "serves a valid manifest" do
    get pwa_manifest_path(format: :json)

    expect(response).to have_http_status(:ok)
    manifest = JSON.parse(response.body)
    expect(manifest["name"]).to eq("Mace Tracker")
    expect(manifest["start_url"]).to eq("/")
  end

  it "serves the service worker" do
    get pwa_service_worker_path(format: :js)

    expect(response).to have_http_status(:ok)
  end

  it "links the manifest from the app layout" do
    get root_path

    expect(response.body).to include('rel="manifest"')
  end
end
