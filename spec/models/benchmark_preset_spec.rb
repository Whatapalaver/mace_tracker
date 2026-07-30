require "rails_helper"

RSpec.describe BenchmarkPreset, type: :model do
  it "has a valid factory" do
    expect(build(:benchmark_preset)).to be_valid
  end

  it "has a valid fixed_reps_for_time factory" do
    expect(build(:benchmark_preset, :fixed_reps_for_time)).to be_valid
  end

  it "has a valid emom factory" do
    expect(build(:benchmark_preset, :emom)).to be_valid
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to belong_to(:exercise) }
    it { is_expected.to belong_to(:session_shape) }

    it "requires interval_work fields when the shape is interval_work" do
      preset = build(:benchmark_preset, planned_work_seconds: nil)

      expect(preset).not_to be_valid
      expect(preset.errors).to be_of_kind(:planned_work_seconds, :blank)
    end

    it "requires target_reps when the shape is fixed_reps_for_time" do
      preset = build(:benchmark_preset, :fixed_reps_for_time, target_reps: nil)

      expect(preset).not_to be_valid
      expect(preset.errors).to be_of_kind(:target_reps, :blank)
    end
  end
end
