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

  describe ".global_ordered" do
    it "returns global shapes in a fixed canonical order, not alphabetical" do
      create(:session_shape, :emom)
      create(:session_shape, :interval_work)
      create(:session_shape, :fixed_reps_for_time)
      create(:session_shape, :sets_and_reps)
      create(:session_shape, name: "custom", user_id: 42)

      expect(SessionShape.global_ordered.map(&:name)).to eq(
        %w[interval_work fixed_reps_for_time emom sets_and_reps]
      )
    end
  end

  describe "#label" do
    it "returns a human-friendly label for known shapes" do
      expect(build(:session_shape, :emom).label).to eq("EMOM")
      expect(build(:session_shape, :sets_and_reps).label).to eq("Sets & reps")
    end

    it "humanizes the name for an unrecognized shape" do
      expect(build(:session_shape, name: "custom_shape").label).to eq("Custom shape")
    end
  end
end
