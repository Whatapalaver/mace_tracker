require "rails_helper"

RSpec.describe Exercise, type: :model do
  it "has a valid factory" do
    expect(build(:exercise)).to be_valid
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it { is_expected.to define_enum_for(:arm).with_values(single: 0, double: 1, n_a: 2) }

    it "is invalid without an arm" do
      exercise = build(:exercise, arm: nil)
      expect(exercise).not_to be_valid
    end

    it "requires name to be unique within the same arm and user scope" do
      create(:exercise, name: "Clean & Press", arm: :single, user_id: nil)
      duplicate = build(:exercise, name: "Clean & Press", arm: :single, user_id: nil)

      expect(duplicate).not_to be_valid
    end

    it "allows the same name for a different arm" do
      create(:exercise, name: "Clean & Press", arm: :single, user_id: nil)
      other_arm = build(:exercise, name: "Clean & Press", arm: :double, user_id: nil)

      expect(other_arm).to be_valid
    end

    it "allows the same name for a different user" do
      create(:exercise, name: "Clean & Press", arm: :single, user_id: nil)
      other_user = build(:exercise, name: "Clean & Press", arm: :single, user_id: 42)

      expect(other_user).to be_valid
    end
  end

  describe "global vs custom scoping" do
    it "defaults to a global exercise (user_id: nil)" do
      expect(build(:exercise).user_id).to be_nil
    end
  end
end
