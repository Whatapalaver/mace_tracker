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

  it "has a valid sets_and_reps factory" do
    expect(build(:session, :sets_and_reps)).to be_valid
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to belong_to(:exercise) }
    it { is_expected.to belong_to(:session_shape) }

    it "rejects a non-positive weight_kg" do
      session = build(:session, weight_kg: 0)
      expect(session).not_to be_valid
    end

    describe "tool" do
      it { is_expected.to belong_to(:tool).optional }

      it "is valid with no tool at all" do
        session = build(:session, tool: nil)
        expect(session).to be_valid
      end

      it "is valid when the tool belongs to the same equipment as the exercise" do
        equipment = create(:equipment)
        session = build(:session, exercise: create(:exercise, equipment: equipment),
                                   tool: create(:tool, equipment: equipment))
        expect(session).to be_valid
      end

      it "is invalid when the tool belongs to different equipment than the exercise" do
        session = build(:session, exercise: create(:exercise, equipment: create(:equipment, name: "Mace")),
                                   tool: create(:tool, equipment: create(:equipment, name: "Kettlebell")))

        expect(session).not_to be_valid
        expect(session.errors[:tool]).to include("must be a piece of Mace equipment")
      end
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

    context "sets_and_reps" do
      it "requires weight_kg and reps" do
        session = build(:session, :sets_and_reps, weight_kg: nil, reps: nil)

        expect(session).not_to be_valid
        expect(session.errors.attribute_names).to contain_exactly(:weight_kg, :reps)
      end

      it "does not require interval-specific fields" do
        session = build(:session, :sets_and_reps, work_seconds: nil, rest_seconds: nil, sets_count: nil)
        expect(session).to be_valid
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
    it "encodes work_seconds, rest_seconds, and sets_count for interval_work" do
      session = build(:session, work_seconds: 300, rest_seconds: 300, sets_count: 3)
      expect(session.structural_value).to eq("300:300:3")
    end

    it "returns reps for fixed_reps_for_time" do
      session = build(:session, :fixed_reps_for_time, reps: 108)
      expect(session.structural_value).to eq("108")
    end

    it "returns reps_per_minute for emom" do
      session = build(:session, :emom, reps_per_minute: 20)
      expect(session.structural_value).to eq("20")
    end

    it "returns reps for sets_and_reps" do
      session = build(:session, :sets_and_reps, reps: 24)
      expect(session.structural_value).to eq("24")
    end
  end

  describe "#weight_agnostic_signature" do
    it "renders interval_work notation without weight" do
      session = build(:session, work_seconds: 300, rest_seconds: 300, sets_count: 3)
      expect(session.weight_agnostic_signature).to eq("3(5mw+5mr)")
    end

    it "renders a bare reps count for fixed_reps_for_time" do
      session = build(:session, :fixed_reps_for_time, reps: 108)
      expect(session.weight_agnostic_signature).to eq("108 reps")
    end

    it "renders a bare reps/min count for emom" do
      session = build(:session, :emom, reps_per_minute: 20)
      expect(session.weight_agnostic_signature).to eq("20 reps/min")
    end

    it "renders a bare reps count for sets_and_reps" do
      session = build(:session, :sets_and_reps, reps: 24)
      expect(session.weight_agnostic_signature).to eq("24 reps")
    end
  end

  describe "#reps_summary" do
    it "lists each set's reps in order, comma-separated" do
      session = create(:session)
      create(:session_set, session: session, set_number: 2, reps: 181)
      create(:session_set, session: session, set_number: 1, reps: 184)
      create(:session_set, session: session, set_number: 3, reps: 175)

      expect(session.reps_summary).to eq("184, 181, 175")
    end

    it "returns an empty string when there are no sets" do
      expect(create(:session).reps_summary).to eq("")
    end
  end
end
