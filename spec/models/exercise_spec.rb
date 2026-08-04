require "rails_helper"

RSpec.describe Exercise, type: :model do
  it "has a valid factory" do
    expect(build(:exercise)).to be_valid
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to belong_to(:equipment) }

    it { is_expected.to define_enum_for(:arm).with_values(single: 0, double: 1, n_a: 2) }

    it "is invalid without an arm" do
      exercise = build(:exercise, arm: nil)
      expect(exercise).not_to be_valid
    end

    it "requires name to be unique within the same equipment, arm, and user scope" do
      equipment = create(:equipment)
      create(:exercise, name: "Clean & Press", equipment: equipment, arm: :single, user_id: nil)
      duplicate = build(:exercise, name: "Clean & Press", equipment: equipment, arm: :single, user_id: nil)

      expect(duplicate).not_to be_valid
    end

    it "allows the same name for a different arm" do
      equipment = create(:equipment)
      create(:exercise, name: "Clean & Press", equipment: equipment, arm: :single, user_id: nil)
      other_arm = build(:exercise, name: "Clean & Press", equipment: equipment, arm: :double, user_id: nil)

      expect(other_arm).to be_valid
    end

    it "allows the same name for a different user" do
      equipment = create(:equipment)
      create(:exercise, name: "Clean & Press", equipment: equipment, arm: :single, user_id: nil)
      other_user = build(:exercise, name: "Clean & Press", equipment: equipment, arm: :single, user_id: 42)

      expect(other_user).to be_valid
    end

    it "allows the same name for a different equipment" do
      create(:exercise, name: "Snatch", equipment: create(:equipment, name: "Kettlebell"), arm: :single, user_id: nil)
      other_equipment = build(:exercise, name: "Snatch", equipment: create(:equipment, name: "Barbell"),
                                          arm: :single, user_id: nil)

      expect(other_equipment).to be_valid
    end
  end

  describe "global vs custom scoping" do
    it "defaults to a global exercise (user_id: nil)" do
      expect(build(:exercise).user_id).to be_nil
    end
  end

  describe ".arm_options" do
    it "returns a human label paired with each enum key" do
      expect(Exercise.arm_options).to contain_exactly(
        [ "Single arm", "single" ], [ "Double arm", "double" ], [ "N/A", "n_a" ]
      )
    end
  end

  describe "#arm_label" do
    it "returns the human label for the current arm" do
      expect(build(:exercise, arm: :n_a).arm_label).to eq("N/A")
    end
  end

  describe "#display_name" do
    it "includes the equipment and arm so same-named variants are distinguishable" do
      exercise = build(:exercise, equipment: build(:equipment, name: "Mace"), name: "360", arm: :single)
      expect(exercise.display_name).to eq("Mace 360 (Single arm)")
    end
  end

  describe "destroying" do
    it "cascades to its sessions and their sets" do
      exercise = create(:exercise)
      session = create(:session, exercise: exercise)
      create(:session_set, session: session, set_number: 1, reps: 20)

      expect { exercise.destroy }.to change(Session, :count).by(-1).and change(SessionSet, :count).by(-1)
    end

    it "cascades to its benchmark presets" do
      exercise = create(:exercise)
      create(:benchmark_preset, exercise: exercise)

      expect { exercise.destroy }.to change(BenchmarkPreset, :count).by(-1)
    end
  end
end
