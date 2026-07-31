module Progression
  module IntervalNotation
    # Ported unchanged from warrior_timer's app/services/intervals/expander.rb — it only ever
    # reads segment[:type]/[:duration] opaquely, so restricting Parser's segment types needed
    # no changes here.
    class Expander
      attr_reader :total_duration

      def initialize(parsed_segments)
        @parsed_segments = parsed_segments
        @total_duration = 0
      end

      def expand
        calculate_round_structure
        build_expanded_segments
      end

      private

      def calculate_round_structure
        # Find consecutive repetition blocks
        @repetition_blocks = []
        current_block = nil

        @parsed_segments.each_with_index do |segment, index|
          if segment[:repetition]
            if current_block.nil?
              current_block = { start_index: index, segments: [] }
            end
            current_block[:segments] << segment
          else
            if current_block
              @repetition_blocks << current_block
              current_block = nil
            end
          end
        end

        # Don't forget the last block if it ends with repetitions
        @repetition_blocks << current_block if current_block

        # Calculate total rounds for each block
        @repetition_blocks.each do |block|
          # Count how many unique patterns we have
          # For now, assume each pair of segments is one round
          # This is a simplification - in reality we'd need to track the original repetition structure
          block[:total_rounds] = count_rounds(block[:segments])
        end
      end

      def count_rounds(segments)
        # Find the pattern length by detecting repetition
        # For a simple case like [work, rest, work, rest], pattern is 2 segments
        # We'll use a heuristic: find the smallest repeating unit
        return 1 if segments.length <= 2

        # Try pattern lengths from 1 up to half the segments
        (1..(segments.length / 2)).each do |pattern_length|
          if segments.length % pattern_length == 0
            # Check if this pattern repeats
            pattern = segments[0...pattern_length]
            is_pattern = true

            (pattern_length...segments.length).step(pattern_length) do |i|
              chunk = segments[i...(i + pattern_length)]
              unless chunks_equal?(pattern, chunk)
                is_pattern = false
                break
              end
            end

            return segments.length / pattern_length if is_pattern
          end
        end

        # If no pattern found, treat each segment as its own round
        segments.length
      end

      def chunks_equal?(chunk1, chunk2)
        return false if chunk1.nil? || chunk2.nil? || chunk1.length != chunk2.length

        chunk1.zip(chunk2).all? do |seg1, seg2|
          seg1[:type] == seg2[:type] && seg1[:duration] == seg2[:duration] && seg1[:name] == seg2[:name]
        end
      end

      def build_expanded_segments
        result = []
        total_segments = @parsed_segments.length
        @total_duration = 0

        # Track which repetition block we're in
        block_index = 0
        current_block = @repetition_blocks[block_index]
        segments_in_current_block = 0
        current_round = 1

        @parsed_segments.each_with_index do |segment, index|
          # Calculate duration
          @total_duration += segment[:duration]

          # Determine round info
          round_number = nil
          total_rounds = nil

          if segment[:repetition]
            # Find which block this belongs to
            while current_block && index >= current_block[:start_index] + current_block[:segments].length
              block_index += 1
              current_block = @repetition_blocks[block_index]
              segments_in_current_block = 0
              current_round = 1
            end

            if current_block
              total_rounds = current_block[:total_rounds]
              pattern_length = current_block[:segments].length / total_rounds

              # Calculate which round we're in based on position within block
              position_in_block = index - current_block[:start_index]
              round_number = (position_in_block / pattern_length) + 1
            end
          end

          expanded_segment = {
            segment_type: segment[:type],
            duration_seconds: segment[:duration],
            round_number: round_number,
            total_rounds: total_rounds,
            segment_index: index,
            total_segments: total_segments
          }

          # Add name if present
          expanded_segment[:name] = segment[:name] if segment[:name]

          # Add bpm if present
          expanded_segment[:bpm] = segment[:bpm] if segment[:bpm]

          result << expanded_segment
        end

        result
      end
    end
  end
end
