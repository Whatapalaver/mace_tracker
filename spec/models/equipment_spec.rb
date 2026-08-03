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
end
