require "rails_helper"

RSpec.describe Tool, type: :model do
  it "has a valid factory" do
    expect(build(:tool)).to be_valid
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to belong_to(:equipment) }

    it "requires name to be unique within the same equipment and user scope" do
      equipment = create(:equipment)
      create(:tool, name: "Eryx Adjustable", equipment: equipment, user_id: nil)
      duplicate = build(:tool, name: "Eryx Adjustable", equipment: equipment, user_id: nil)

      expect(duplicate).not_to be_valid
    end

    it "allows the same name for a different equipment" do
      create(:tool, name: "Wrecking Ball", equipment: create(:equipment, name: "Mace"), user_id: nil)
      other_equipment = build(:tool, name: "Wrecking Ball", equipment: create(:equipment, name: "Kettlebell"),
                                      user_id: nil)

      expect(other_equipment).to be_valid
    end

    it "allows the same name for a different user" do
      equipment = create(:equipment)
      create(:tool, name: "Eryx Adjustable", equipment: equipment, user_id: nil)
      other_user = build(:tool, name: "Eryx Adjustable", equipment: equipment, user_id: 42)

      expect(other_user).to be_valid
    end
  end

  describe "#display_name" do
    it "includes the equipment name" do
      tool = build(:tool, equipment: build(:equipment, name: "Mace"), name: "Eryx Adjustable")
      expect(tool.display_name).to eq("Mace: Eryx Adjustable")
    end
  end

  describe "destroying" do
    it "nullifies tool_id on sessions rather than destroying them" do
      equipment = create(:equipment)
      tool = create(:tool, equipment: equipment)
      session = create(:session, exercise: create(:exercise, equipment: equipment), tool: tool)

      expect { tool.destroy }.to change(Session, :count).by(0)
      expect(session.reload.tool_id).to be_nil
    end
  end

  describe ".grouped_options" do
    it "groups tools by equipment name, only for equipment that has tools" do
      mace = create(:equipment, name: "Mace")
      create(:equipment, name: "Kettlebell") # no tools registered — left out
      eryx = create(:tool, name: "Eryx Adjustable", equipment: mace)
      wrecking_ball = create(:tool, name: "Wrecking Ball", equipment: mace)

      expect(Tool.grouped_options).to eq(
        [ [ "Mace", [ [ "Eryx Adjustable", eryx.id ], [ "Wrecking Ball", wrecking_ball.id ] ] ] ]
      )
    end

    it "returns an empty array when no tools exist" do
      create(:equipment)

      expect(Tool.grouped_options).to eq([])
    end
  end

  describe ".resolve_filter_param" do
    it "returns nil for both when the raw value is blank" do
      expect(Tool.resolve_filter_param(nil)).to eq([ nil, nil ])
      expect(Tool.resolve_filter_param("")).to eq([ nil, nil ])
    end

    it "treats a bare id as an equipment id with no tool" do
      expect(Tool.resolve_filter_param("3")).to eq([ "3", nil ])
    end

    it "resolves a tool-prefixed value to its tool and that tool's equipment id" do
      equipment = create(:equipment)
      tool = create(:tool, equipment: equipment)

      resolved_equipment_id, resolved_tool = Tool.resolve_filter_param("tool-#{tool.id}")

      expect(resolved_equipment_id).to eq(equipment.id.to_s)
      expect(resolved_tool).to eq(tool)
    end

    it "returns nil for both when the tool id doesn't exist" do
      expect(Tool.resolve_filter_param("tool-999999")).to eq([ nil, nil ])
    end
  end
end
