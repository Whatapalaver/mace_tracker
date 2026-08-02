require "rails_helper"

RSpec.describe Session, type: :model do
  it "has a valid factory" do
    expect(build(:session)).to be_valid
  end

  it "has a valid fixed_reps_for_time factory" do
    expect(build(:session, :fixed_reps_for_time)).to be_valid
  end

  it "has a valid emom factory" do
    expect(build(:session, :emom)).to be_valid
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to belong_to(:exercise) }
    it { is_expected.to belong_to(:session_shape) }

    it "rejects a non-positive weight_kg" do
      session = build(:session, weight_kg: 0)
      expect(session).not_to be_valid
    end

    context "interval_work" do
      it "requires weight_kg, work_seconds, rest_seconds, and sets_count" do
        session = build(:session, weight_kg: nil, work_seconds: nil,
                                   rest_seconds: nil, sets_count: nil)

        expect(session).not_to be_valid
        expect(session.errors.attribute_names).to contain_exactly(
          :weight_kg, :work_seconds, :rest_seconds, :sets_count
        )
      end

      it "does not require reps or reps_per_minute" do
        session = build(:session, reps: nil, reps_per_minute: nil)
        expect(session).to be_valid
      end

      it "allows rest_seconds to be 0 (a single-set all-out effort)" do
        session = build(:session, rest_seconds: 0)
        expect(session).to be_valid
      end

      it "rejects a negative rest_seconds" do
        session = build(:session, rest_seconds: -1)
        expect(session).not_to be_valid
      end

      it "rejects a non-positive work_seconds" do
        session = build(:session, work_seconds: 0)
        expect(session).not_to be_valid
      end
    end

    context "fixed_reps_for_time" do
      it "requires weight_kg and reps" do
        session = build(:session, :fixed_reps_for_time, weight_kg: nil, reps: nil)

        expect(session).not_to be_valid
        expect(session.errors.attribute_names).to contain_exactly(:weight_kg, :reps)
      end

      it "does not require interval-specific fields" do
        session = build(:session, :fixed_reps_for_time,
                         work_seconds: nil, rest_seconds: nil, sets_count: nil)
        expect(session).to be_valid
      end
    end

    context "emom" do
      it "requires weight_kg and reps_per_minute" do
        session = build(:session, :emom, weight_kg: nil, reps_per_minute: nil)

        expect(session).not_to be_valid
        expect(session.errors.attribute_names).to contain_exactly(:weight_kg, :reps_per_minute)
      end
    end
  end

  describe "is_benchmark" do
    it "defaults to false" do
      expect(create(:session).is_benchmark).to eq(false)
    end

    it "is forced true whenever a benchmark_preset is attached" do
      preset = create(:benchmark_preset)
      session = create(:session, benchmark_preset: preset, is_benchmark: false)

      expect(session.is_benchmark).to eq(true)
    end

    it "can be set explicitly true for a one-off effort without a preset" do
      session = create(:session, is_benchmark: true)

      expect(session.is_benchmark).to eq(true)
      expect(session.benchmark_preset_id).to be_nil
    end
  end

  describe "#structural_value" do
    it "returns work_seconds for interval_work" do
      session = build(:session, work_seconds: 300)
      expect(session.structural_value).to eq(300)
    end

    it "returns reps for fixed_reps_for_time" do
      session = build(:session, :fixed_reps_for_time, reps: 108)
      expect(session.structural_value).to eq(108)
    end

    it "returns reps_per_minute for emom" do
      session = build(:session, :emom, reps_per_minute: 20)
      expect(session.structural_value).to eq(20)
    end
  end
end
