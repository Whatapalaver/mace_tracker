require "rails_helper"

# Ported from warrior_timer's spec/services/intervals/parser_spec.rb, trimmed to the w/r
# segment types mace_tracker supports (warrior_timer also has warmup/cooldown/prepare) — see
# the "restricted to work/rest" context below for coverage of that restriction itself.
RSpec.describe Progression::IntervalNotation::Parser do
  describe "#parse" do
    context "with simple segments" do
      it "parses bare seconds" do
        result = described_class.new("30w").parse
        expect(result).to eq([
          { type: :work, duration: 30 }
        ])
      end

      it "parses rest segments" do
        result = described_class.new("15r").parse
        expect(result).to eq([
          { type: :rest, duration: 15 }
        ])
      end
    end

    context "with minute notation" do
      it "parses minutes with m suffix" do
        result = described_class.new("5mw").parse
        expect(result).to eq([
          { type: :work, duration: 300 }
        ])
      end

      it "parses multiple minutes" do
        result = described_class.new("3mr").parse
        expect(result).to eq([
          { type: :rest, duration: 180 }
        ])
      end
    end

    context "with decimal minute notation" do
      it "parses 1.5m as 90 seconds" do
        result = described_class.new("1.5mw").parse
        expect(result).to eq([
          { type: :work, duration: 90 }
        ])
      end

      it "parses 0.5m as 30 seconds" do
        result = described_class.new("0.5mr").parse
        expect(result).to eq([
          { type: :rest, duration: 30 }
        ])
      end

      it "parses 2.5m as 150 seconds" do
        result = described_class.new("2.5mw").parse
        expect(result).to eq([
          { type: :work, duration: 150 }
        ])
      end

      it "parses concatenated decimal minutes" do
        result = described_class.new("1.5mw0.5mr").parse
        expect(result).to eq([
          { type: :work, duration: 90 },
          { type: :rest, duration: 30 }
        ])
      end

      it "parses decimal minutes inside repetitions" do
        result = described_class.new("3(1.5mw0.5mr)").parse
        expected = []
        3.times do
          expected << { type: :work, duration: 90, repetition: true }
          expected << { type: :rest, duration: 30, repetition: true }
        end
        expect(result).to eq(expected)
      end

      it "rounds to the nearest second for odd decimals" do
        # 0.33m = 19.8s, rounds to 20
        result = described_class.new("0.33mw").parse
        expect(result).to eq([
          { type: :work, duration: 20 }
        ])
      end
    end

    context "with colon notation" do
      it "parses minutes:seconds format" do
        result = described_class.new("1:30w").parse
        expect(result).to eq([
          { type: :work, duration: 90 }
        ])
      end

      it "parses longer durations" do
        result = described_class.new("2:45r").parse
        expect(result).to eq([
          { type: :rest, duration: 165 }
        ])
      end
    end

    context "with sequences" do
      it "parses plus-separated segments" do
        result = described_class.new("30w+30r").parse
        expect(result).to eq([
          { type: :work, duration: 30 },
          { type: :rest, duration: 30 }
        ])
      end

      it "parses concatenated segments without plus" do
        result = described_class.new("30w30r").parse
        expect(result).to eq([
          { type: :work, duration: 30 },
          { type: :rest, duration: 30 }
        ])
      end

      it "parses ladder-style concatenated sequences" do
        result = described_class.new("30w30r45w30r1mw30r").parse
        expect(result).to eq([
          { type: :work, duration: 30 },
          { type: :rest, duration: 30 },
          { type: :work, duration: 45 },
          { type: :rest, duration: 30 },
          { type: :work, duration: 60 },
          { type: :rest, duration: 30 }
        ])
      end

      it "parses mixed time format ladders" do
        result = described_class.new("30w30r45w30r1mw30r1:30w30r2mw").parse
        expect(result).to eq([
          { type: :work, duration: 30 },
          { type: :rest, duration: 30 },
          { type: :work, duration: 45 },
          { type: :rest, duration: 30 },
          { type: :work, duration: 60 },
          { type: :rest, duration: 30 },
          { type: :work, duration: 90 },
          { type: :rest, duration: 30 },
          { type: :work, duration: 120 }
        ])
      end

      it "parses mixed concatenation and plus syntax" do
        result = described_class.new("10w30r+20w40r").parse
        expect(result).to eq([
          { type: :work, duration: 10 },
          { type: :rest, duration: 30 },
          { type: :work, duration: 20 },
          { type: :rest, duration: 40 }
        ])
      end

      it "handles all three syntax styles equivalently" do
        codes = [ "10w30r20w40r", "10w30r+20w40r", "10w+30r+20w+40r" ]
        expected = [
          { type: :work, duration: 10 },
          { type: :rest, duration: 30 },
          { type: :work, duration: 20 },
          { type: :rest, duration: 40 }
        ]
        codes.each do |code|
          expect(described_class.new(code).parse).to eq(expected)
        end
      end
    end

    context "with repetitions" do
      it "parses simple repetitions" do
        result = described_class.new("10(30w30r)").parse
        expected = []
        10.times do
          expected << { type: :work, duration: 30, repetition: true }
          expected << { type: :rest, duration: 30, repetition: true }
        end
        expect(result).to eq(expected)
      end

      it "parses repetitions with plus notation inside" do
        result = described_class.new("5(30w+15r)").parse
        expected = []
        5.times do
          expected << { type: :work, duration: 30, repetition: true }
          expected << { type: :rest, duration: 15, repetition: true }
        end
        expect(result).to eq(expected)
      end

      it "parses single item repetition" do
        result = described_class.new("8(45w)").parse
        expected = []
        8.times do
          expected << { type: :work, duration: 45, repetition: true }
        end
        expect(result).to eq(expected)
      end

      it "parses bare group with no count as a single repetition" do
        result = described_class.new("(30w15r)").parse
        expect(result).to eq([
          { type: :work, duration: 30, repetition: true },
          { type: :rest, duration: 15, repetition: true }
        ])
      end

      it "parses bare group mixed with counted groups" do
        result = described_class.new("2(5mw@42bpm+10mr)+(5mw@45bpm)").parse
        expect(result.length).to eq(5)
        expect(result[0]).to include(type: :work, duration: 300, bpm: 42)
        expect(result[4]).to include(type: :work, duration: 300, bpm: 45)
      end
    end

    context "with nested repetitions" do
      it "parses two levels of nesting" do
        result = described_class.new("3(2(30w15r)60r)").parse
        expected = []
        3.times do
          2.times do
            expected << { type: :work, duration: 30, repetition: true }
            expected << { type: :rest, duration: 15, repetition: true }
          end
          expected << { type: :rest, duration: 60, repetition: true }
        end
        expect(result).to eq(expected)
      end
    end

    context "with complex combinations" do
      it "parses tabata-style workout" do
        result = described_class.new("20(20w10r)").parse
        expected = []
        20.times do
          expected << { type: :work, duration: 20, repetition: true }
          expected << { type: :rest, duration: 10, repetition: true }
        end
        expect(result).to eq(expected)
      end
    end

    context "restricted to work/rest (mace_tracker doesn't need warmup/cooldown/prepare)" do
      it "raises for warmup" do
        expect { described_class.new("60wu").parse }.to raise_error(Progression::IntervalNotation::Parser::ParseError)
      end

      it "raises for cooldown" do
        expect { described_class.new("45cd").parse }.to raise_error(Progression::IntervalNotation::Parser::ParseError)
      end

      it "raises for prepare" do
        expect { described_class.new("10p").parse }.to raise_error(Progression::IntervalNotation::Parser::ParseError)
      end
    end

    context "with invalid syntax" do
      it "raises error for invalid segment type" do
        expect { described_class.new("30x").parse }.to raise_error(Progression::IntervalNotation::Parser::ParseError)
      end

      it "raises error for invalid time format" do
        expect { described_class.new("abcw").parse }.to raise_error(Progression::IntervalNotation::Parser::ParseError)
      end

      it "raises error for empty string" do
        expect { described_class.new("").parse }.to raise_error(Progression::IntervalNotation::Parser::ParseError, /empty/i)
      end

      it "raises error for mismatched parentheses" do
        expect { described_class.new("10(30w").parse }.to raise_error(Progression::IntervalNotation::Parser::ParseError, /parenthes/i)
      end

      it "raises error for empty repetition" do
        expect { described_class.new("10()").parse }.to raise_error(Progression::IntervalNotation::Parser::ParseError)
      end
    end

    context "with named segments" do
      it "parses inline segment name" do
        result = described_class.new("30w[Squat]").parse
        expect(result).to eq([
          { type: :work, duration: 30, name: "Squat" }
        ])
      end

      it "parses named work and unnamed rest" do
        result = described_class.new("30w[Squat]30r").parse
        expect(result).to eq([
          { type: :work, duration: 30, name: "Squat" },
          { type: :rest, duration: 30 }
        ])
      end

      it "handles names with hyphens (converts to spaces)" do
        result = described_class.new("30w[Jumping-Jacks]").parse
        expect(result).to eq([
          { type: :work, duration: 30, name: "Jumping Jacks" }
        ])
      end

      it "handles names with underscores (converts to spaces)" do
        result = described_class.new("30w[Jumping_Jacks]").parse
        expect(result).to eq([
          { type: :work, duration: 30, name: "Jumping Jacks" }
        ])
      end

      it "parses named rest segment (active rest)" do
        result = described_class.new("30r[Jog]").parse
        expect(result).to eq([
          { type: :rest, duration: 30, name: "Jog" }
        ])
      end

      it "parses circuit shorthand with names" do
        result = described_class.new("(30w30r)*[A,B,C]").parse
        expect(result.length).to eq(6)
        expect(result[0]).to include(type: :work, duration: 30, name: "A", repetition: true)
        expect(result[1]).to include(type: :rest, duration: 30, repetition: true)
        expect(result[1][:name]).to be_nil # Rest segments don't get names
        expect(result[2]).to include(type: :work, duration: 30, name: "B", repetition: true)
        expect(result[3]).to include(type: :rest, duration: 30, repetition: true)
        expect(result[4]).to include(type: :work, duration: 30, name: "C", repetition: true)
        expect(result[5]).to include(type: :rest, duration: 30, repetition: true)
      end

      it "parses circuit shorthand with repetition count" do
        result = described_class.new("2((30w30r)*[A,B])").parse
        expect(result.length).to eq(8)
        # First set
        expect(result[0]).to include(type: :work, duration: 30, name: "A", repetition: true)
        expect(result[1]).to include(type: :rest, duration: 30, repetition: true)
        expect(result[2]).to include(type: :work, duration: 30, name: "B", repetition: true)
        expect(result[3]).to include(type: :rest, duration: 30, repetition: true)
        # Second set
        expect(result[4]).to include(type: :work, duration: 30, name: "A", repetition: true)
        expect(result[5]).to include(type: :rest, duration: 30, repetition: true)
        expect(result[6]).to include(type: :work, duration: 30, name: "B", repetition: true)
        expect(result[7]).to include(type: :rest, duration: 30, repetition: true)
      end

      it "handles Tabata with all segments named" do
        result = described_class.new(
          "(20w10r)*[Burpees1,Burpees2,Burpees3,Burpees4,Burpees5,Burpees6,Burpees7,Burpees8]"
        ).parse
        expect(result.length).to eq(16)
        work_segments = result.select { |s| s[:type] == :work }
        expect(work_segments.length).to eq(8)
        work_segments.each_with_index do |seg, i|
          expect(seg[:name]).to eq("Burpees#{i + 1}")
        end
        result.select { |s| s[:type] == :rest }.each do |seg|
          expect(seg[:name]).to be_nil
        end
      end
    end

    context "with @bpm notation" do
      it "parses segment with bpm" do
        result = described_class.new("60w@30bpm").parse
        expect(result).to eq([
          { type: :work, duration: 60, bpm: 30 }
        ])
      end

      it "parses segment with bpm and name" do
        result = described_class.new("60w@30bpm[Kettlebell]").parse
        expect(result).to eq([
          { type: :work, duration: 60, bpm: 30, name: "Kettlebell" }
        ])
      end

      it "parses rest segment with bpm" do
        result = described_class.new("30r@15bpm").parse
        expect(result).to eq([
          { type: :rest, duration: 30, bpm: 15 }
        ])
      end

      it "parses multiple segments with different bpm values (with +)" do
        result = described_class.new("60w@30bpm+30r+60w@25bpm+30r").parse
        expect(result).to eq([
          { type: :work, duration: 60, bpm: 30 },
          { type: :rest, duration: 30 },
          { type: :work, duration: 60, bpm: 25 },
          { type: :rest, duration: 30 }
        ])
      end

      it "parses concatenated segments with bpm (no + needed)" do
        result = described_class.new("60w@30bpm30r60w@25bpm30r").parse
        expect(result).to eq([
          { type: :work, duration: 60, bpm: 30 },
          { type: :rest, duration: 30 },
          { type: :work, duration: 60, bpm: 25 },
          { type: :rest, duration: 30 }
        ])
      end

      it "parses Viking Warrior conditioning protocol" do
        result = described_class.new("1mw@10bpm+1mw@14bpm+1mw@18bpm+1mw@22bpm+1mw").parse
        expect(result).to eq([
          { type: :work, duration: 60, bpm: 10 },
          { type: :work, duration: 60, bpm: 14 },
          { type: :work, duration: 60, bpm: 18 },
          { type: :work, duration: 60, bpm: 22 },
          { type: :work, duration: 60 }
        ])
      end

      it "parses bpm with decimal minutes" do
        result = described_class.new("1.5mw@40bpm").parse
        expect(result).to eq([
          { type: :work, duration: 90, bpm: 40 }
        ])
      end

      it "parses repetitions with bpm" do
        result = described_class.new("3(60w@30bpm+30r)").parse
        expected = []
        3.times do
          expected << { type: :work, duration: 60, bpm: 30, repetition: true }
          expected << { type: :rest, duration: 30, repetition: true }
        end
        expect(result).to eq(expected)
      end

      it "parses circuit shorthand with bpm on work segments" do
        result = described_class.new("(60w@30bpm+30r)*[A,B,C]").parse
        expect(result.length).to eq(6)
        expect(result[0]).to include(type: :work, duration: 60, bpm: 30, name: "A", repetition: true)
        expect(result[1]).to include(type: :rest, duration: 30, repetition: true)
        expect(result[2]).to include(type: :work, duration: 60, bpm: 30, name: "B", repetition: true)
        expect(result[3]).to include(type: :rest, duration: 30, repetition: true)
        expect(result[4]).to include(type: :work, duration: 60, bpm: 30, name: "C", repetition: true)
        expect(result[5]).to include(type: :rest, duration: 30, repetition: true)
      end

      it "parses mixed segments with and without bpm" do
        result = described_class.new("30w@60bpm+30r+45w+30r+60w@50bpm").parse
        expect(result).to eq([
          { type: :work, duration: 30, bpm: 60 },
          { type: :rest, duration: 30 },
          { type: :work, duration: 45 },
          { type: :rest, duration: 30 },
          { type: :work, duration: 60, bpm: 50 }
        ])
      end
    end

    context "with @reps notation" do
      it "converts reps to bpm for a 15s interval" do
        result = described_class.new("15w@7reps").parse
        # (7+1) beats needed for 7 inter-beat intervals = 8 * 60 / 15 = 32 BPM
        expect(result).to eq([ { type: :work, duration: 15, bpm: 32 } ])
      end

      it "converts reps to bpm for a 1-minute interval" do
        result = described_class.new("1mw@10reps").parse
        # (10+1) * 60 / 60 = 11 BPM
        expect(result).to eq([ { type: :work, duration: 60, bpm: 11 } ])
      end

      it "handles the VWC 15:15 protocol with 8 reps" do
        result = described_class.new("2(15w@8reps+15r)").parse
        # (8+1) * 60 / 15 = 36 BPM -> 9 beats -> 8 inter-beat intervals
        result.select { |s| s[:type] == :work }.each do |seg|
          expect(seg[:bpm]).to eq(36)
        end
      end

      it "handles the cMVO2 test with reps notation" do
        result = described_class.new("1mw@10reps+1mw@14reps+1mw@18reps+1mw@22reps+1mw").parse
        expect(result[0]).to include(type: :work, duration: 60, bpm: 11)
        expect(result[1]).to include(type: :work, duration: 60, bpm: 15)
        expect(result[2]).to include(type: :work, duration: 60, bpm: 19)
        expect(result[3]).to include(type: :work, duration: 60, bpm: 23)
        expect(result[4]).to eq({ type: :work, duration: 60 })
      end

      it "combines reps notation with a name" do
        result = described_class.new("15w@8reps[Snatch]").parse
        expect(result).to eq([ { type: :work, duration: 15, bpm: 36, name: "Snatch" } ])
      end
    end
  end
end
