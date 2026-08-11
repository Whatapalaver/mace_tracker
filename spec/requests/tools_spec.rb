require "rails_helper"

RSpec.describe "Tools", type: :request do
  describe "GET /tools" do
    it "lists existing tools" do
      create(:tool, name: "Eryx Adjustable", equipment: create(:equipment, name: "Mace"))

      get tools_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mace")
      expect(response.body).to include("Eryx Adjustable")
    end

    it "warns how many sessions would be cleared alongside a tool" do
      tool = create(:tool)
      create(:session, exercise: create(:exercise, equipment: tool.equipment), tool: tool)

      get tools_path

      expect(response.body).to include("cleared from 1 logged session")
    end

    it "uses a plain confirmation when a tool has no logged sessions" do
      create(:tool)

      get tools_path

      expect(response.body).to include("Delete this tool?")
    end
  end

  describe "GET /tools/new" do
    it "renders the new tool form" do
      get new_tool_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /tools" do
    it "creates a tool and redirects to the index" do
      equipment = create(:equipment, name: "Mace")

      expect {
        post tools_path, params: { tool: { name: "Wrecking Ball", equipment_id: equipment.id, notes: "" } }
      }.to change(Tool, :count).by(1)

      expect(response).to redirect_to(tools_path)
    end

    it "re-renders the form with errors when invalid" do
      expect {
        post tools_path, params: { tool: { name: "" } }
      }.not_to change(Tool, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /tools/:id/edit" do
    it "renders the edit form pre-filled with the tool's attributes" do
      tool = create(:tool, name: "Wrecking Ball", equipment: create(:equipment, name: "Mace"))

      get edit_tool_path(tool)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Wrecking Ball")
    end
  end

  describe "PATCH /tools/:id" do
    it "updates the tool and redirects to the index" do
      tool = create(:tool, name: "Wrecking Ball")

      patch tool_path(tool), params: { tool: { name: "Wrecking Ball V2" } }

      expect(response).to redirect_to(tools_path)
      expect(tool.reload.name).to eq("Wrecking Ball V2")
    end

    it "re-renders the form with errors when invalid" do
      tool = create(:tool)

      patch tool_path(tool), params: { tool: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(tool.reload.name).to be_present
    end
  end

  describe "DELETE /tools/:id" do
    it "deletes a tool with no logged sessions" do
      tool = create(:tool)

      expect { delete tool_path(tool) }.to change(Tool, :count).by(-1)

      expect(response).to redirect_to(tools_path)
    end

    it "keeps sessions when deleting a tool, just clearing their tool_id" do
      tool = create(:tool)
      session = create(:session, exercise: create(:exercise, equipment: tool.equipment), tool: tool)

      expect { delete tool_path(tool) }.to change(Tool, :count).by(-1)
        .and change(Session, :count).by(0)

      expect(session.reload.tool_id).to be_nil
    end
  end
end
