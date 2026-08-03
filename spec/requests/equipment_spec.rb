require "rails_helper"

RSpec.describe "Equipment", type: :request do
  describe "GET /equipment" do
    it "lists existing equipment" do
      create(:equipment, name: "Mace")

      get equipment_index_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mace")
    end
  end

  describe "GET /equipment/new" do
    it "renders the new equipment form" do
      get new_equipment_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /equipment" do
    it "creates equipment and redirects to the index" do
      expect {
        post equipment_index_path, params: { equipment: { name: "Kettlebell" } }
      }.to change(Equipment, :count).by(1)

      expect(response).to redirect_to(equipment_index_path)
    end

    it "re-renders the form with errors when invalid" do
      expect {
        post equipment_index_path, params: { equipment: { name: "" } }
      }.not_to change(Equipment, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
