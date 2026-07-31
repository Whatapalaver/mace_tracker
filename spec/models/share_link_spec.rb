require "rails_helper"

RSpec.describe ShareLink, type: :model do
  it "has a valid factory" do
    expect(build(:share_link)).to be_valid
  end

  it "auto-generates a unique token on create" do
    share_link = create(:share_link)

    expect(share_link.token).to be_present
  end

  it "generates a different token for each share link" do
    first = create(:share_link)
    second = create(:share_link)

    expect(first.token).not_to eq(second.token)
  end

  describe "#regenerate_token" do
    it "replaces the token, invalidating the old one" do
      share_link = create(:share_link)
      old_token = share_link.token

      share_link.regenerate_token

      expect(share_link.token).not_to eq(old_token)
      expect(ShareLink.find_by(token: old_token)).to be_nil
    end
  end

  describe "#expired?" do
    it "is false when expires_at is nil (permanent link)" do
      expect(build(:share_link, expires_at: nil).expired?).to eq(false)
    end

    it "is false when expires_at is in the future" do
      expect(build(:share_link, expires_at: 1.day.from_now).expired?).to eq(false)
    end

    it "is true when expires_at is in the past" do
      expect(build(:share_link, :expired).expired?).to eq(true)
    end
  end

  describe "#exercise and #sessions" do
    it "returns nil exercise and all sessions when scope is empty (unscoped link)" do
      mace = create(:exercise, name: "Mace 360")
      kettlebell = create(:exercise, name: "Kettlebell Swing")
      create(:session, exercise: mace)
      create(:session, exercise: kettlebell)

      share_link = create(:share_link)

      expect(share_link.exercise).to be_nil
      expect(share_link.sessions.count).to eq(2)
    end

    it "restricts sessions to the scoped exercise" do
      mace = create(:exercise, name: "Mace 360")
      kettlebell = create(:exercise, name: "Kettlebell Swing")
      mace_session = create(:session, exercise: mace)
      create(:session, exercise: kettlebell)

      share_link = create(:share_link, :scoped_to_exercise, exercise: mace)

      expect(share_link.exercise).to eq(mace)
      expect(share_link.sessions).to contain_exactly(mace_session)
    end
  end

  describe "#description" do
    it "describes an unscoped link as covering all exercises" do
      expect(build(:share_link).description).to eq("All exercises")
    end

    it "describes a scoped link by exercise name" do
      exercise = create(:exercise, name: "Mace 360", arm: :double)
      share_link = build(:share_link, :scoped_to_exercise, exercise: exercise)

      expect(share_link.description).to eq("Mace 360 (Double arm) only")
    end
  end
end
