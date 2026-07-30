require "rails_helper"

RSpec.describe SessionShape, type: :model do
  it "has a valid factory" do
    expect(build(:session_shape)).to be_valid
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "requires name to be unique within the same user scope" do
      create(:session_shape, name: "interval_work", user_id: nil)
      duplicate = build(:session_shape, name: "interval_work", user_id: nil)

      expect(duplicate).not_to be_valid
    end

    it "allows the same name for a different user" do
      create(:session_shape, name: "interval_work", user_id: nil)
      other_user = build(:session_shape, name: "interval_work", user_id: 42)

      expect(other_user).to be_valid
    end
  end
end
