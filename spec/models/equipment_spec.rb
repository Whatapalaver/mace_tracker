require "rails_helper"

RSpec.describe Equipment, type: :model do
  it "has a valid factory" do
    expect(build(:equipment)).to be_valid
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "requires name to be unique within the same user scope" do
      create(:equipment, name: "Mace", user_id: nil)
      duplicate = build(:equipment, name: "Mace", user_id: nil)

      expect(duplicate).not_to be_valid
    end

    it "allows the same name for a different user" do
      create(:equipment, name: "Mace", user_id: nil)
      other_user = build(:equipment, name: "Mace", user_id: 42)

      expect(other_user).to be_valid
    end
  end

  describe "#exercises" do
    it "returns exercises belonging to this equipment" do
      equipment = create(:equipment)
      exercise = create(:exercise, equipment: equipment)

      expect(equipment.exercises).to contain_exactly(exercise)
    end
  end

  describe "destroying" do
    it "cascades to its tools" do
      equipment = create(:equipment)
      create(:tool, equipment: equipment)

      expect { equipment.destroy }.to change(Tool, :count).by(-1)
    end
  end

  describe ".filter_options" do
    it "gives every equipment an \"all\" option plus one option per tool, grouped by equipment name" do
      mace = create(:equipment, name: "Mace")
      kettlebell = create(:equipment, name: "Kettlebell")
      eryx = create(:tool, name: "Eryx Adjustable", equipment: mace)
      wrecking_ball = create(:tool, name: "Wrecking Ball", equipment: mace)

      expect(Equipment.filter_options).to eq(
        [
          [ "Kettlebell", [ [ "All Kettlebell", kettlebell.id.to_s ] ] ],
          [ "Mace", [
            [ "All Mace", mace.id.to_s ],
            [ "Eryx Adjustable", "tool-#{eryx.id}" ],
            [ "Wrecking Ball", "tool-#{wrecking_ball.id}" ]
          ] ]
        ]
      )
    end

    it "still lists equipment with no tools registered" do
      equipment = create(:equipment, name: "Mace")

      expect(Equipment.filter_options).to eq([ [ "Mace", [ [ "All Mace", equipment.id.to_s ] ] ] ])
    end
  end
end
