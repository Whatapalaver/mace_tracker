require "rails_helper"

RSpec.describe "ShareLinks", type: :request do
  describe "GET /share_links" do
    it "lists existing links with their shareable URL" do
      share_link = create(:share_link)

      get share_links_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(share_link.token)
    end
  end

  describe "POST /share_links" do
    it "creates an unscoped, permanent link by default" do
      expect {
        post share_links_path, params: { share_link: {} }
      }.to change(ShareLink, :count).by(1)

      share_link = ShareLink.last
      expect(share_link.scope).to eq({})
      expect(share_link.expires_at).to be_nil
      expect(response).to redirect_to(share_links_path)
    end

    it "creates a link scoped to a single exercise" do
      exercise = create(:exercise)

      post share_links_path, params: { share_link: { exercise_id: exercise.id } }

      expect(ShareLink.last.exercise).to eq(exercise)
    end

    it "creates a time-boxed link" do
      post share_links_path, params: { share_link: { expires_at: "2027-01-01" } }

      expect(ShareLink.last.expires_at.to_date).to eq(Date.new(2027, 1, 1))
    end
  end

  describe "DELETE /share_links/:id" do
    it "revokes (deletes) the share link" do
      share_link = create(:share_link)

      expect {
        delete share_link_path(share_link)
      }.to change(ShareLink, :count).by(-1)

      expect(response).to redirect_to(share_links_path)
    end
  end

  describe "PATCH /share_links/:id/regenerate" do
    it "replaces the token so the old link stops working" do
      share_link = create(:share_link)
      old_token = share_link.token

      patch regenerate_share_link_path(share_link)

      expect(share_link.reload.token).not_to eq(old_token)
      expect(response).to redirect_to(share_links_path)
    end
  end
end
