module Progression
  module IntervalNotation
    # Ported from warrior_timer's app/services/intervals/parser.rb, restricted to the two
    # segment types mace_tracker needs (work/rest) — warrior_timer also supports warmup/
    # cooldown/prepare, which don't apply here. The core tokenizing/nesting/circuit-shorthand
    # grammar is otherwise unchanged.
    class Parser
      class ParseError < StandardError; end

      SEGMENT_TYPES = {
        "w" => :work,
        "r" => :rest
      }.freeze

      def initialize(input)
        @input = input.to_s.strip
      end

      def parse
        raise ParseError, "Input cannot be empty" if @input.empty?

        parse_sequence(@input)
      end

      private

      def parse_sequence(input)
        # First check if there's explicit + sequencing
        if input.include?("+")
          # Split on + to get individual segments or groups, but respect parentheses
          segments = []
          parts = split_respecting_parens(input, "+")
          parts.each do |part|
            segments.concat(parse_part(part.strip))
          end
          return segments
        end

        # No explicit +, treat as concatenated segments
        parse_inner_sequence(input)
      end

      def parse_part(part)
        # Check for circuit shorthand: (...))*[name1,name2,...]
        if part =~ /^(\d+)?\((.*)\)\*\[(.*)\]$/
          count = $1 ? $1.to_i : 1
          inner = $2
          names_str = $3

          raise ParseError, "Empty repetition" if inner.strip.empty?

          names = names_str.split(",").map { |n| decode_name(n.strip) }

          # Parse the inner content
          inner_segments = parse_inner_sequence(inner)

          # Apply names to work segments
          apply_names_to_circuit(inner_segments, names, count)
        # Check if this is a repetition: N(...) or bare (...) treated as 1(...)
        elsif part =~ /^(\d*)\((.*)\)$/
          count = $1.empty? ? 1 : $1.to_i
          inner = $2

          raise ParseError, "Empty repetition" if inner.strip.empty?

          # Parse the inner content - could have + or be concatenated
          inner_segments = parse_inner_sequence(inner)

          # Repeat the segments
          result = []
          count.times do
            inner_segments.each do |seg|
              result << seg.merge(repetition: true)
            end
          end
          result
        else
          # Could be a simple segment or concatenated segments
          # Check if it matches a valid simple segment pattern with optional name
          # Valid segment types: w, r (1 char)
          if part =~ /^(\d+(?:\.\d+)?(?::\d+)?m?)([wr])(?:@(\d+)(?:bpm|reps))?(?:\[([^\]]+)\])?$/
            # Simple segment
            [ parse_segment(part) ]
          else
            # Must be concatenated segments - tokenize them
            parse_inner_sequence(part)
          end
        end
      end

      def parse_inner_sequence(input)
        # First check if there's a + (explicit sequencing)
        if input.include?("+")
          return parse_sequence(input)
        end

        # Otherwise, split into individual segments by tokenizing
        # This handles cases like: 30w15r (two segments) or 2(30w15r)60r (nested + segment)
        tokens = tokenize_concatenated(input)

        # Validate that we got tokens - if input had content but produced no tokens, it's invalid
        if tokens.empty? && !input.strip.empty?
          raise ParseError, "Unable to parse input: #{input}"
        end

        segments = []

        tokens.each do |token|
          if token =~ /\)\*\[/
            # This is a circuit shorthand pattern
            segments.concat(parse_part(token))
          elsif token =~ /^\d*\(/
            # This is a nested repetition (with or without leading number)
            segments.concat(parse_part(token))
          else
            # This is a simple segment
            segments << parse_segment(token)
          end
        end

        segments
      end

      def tokenize_concatenated(input)
        tokens = []
        i = 0

        while i < input.length
          # Skip whitespace
          if input[i] =~ /\s/
            i += 1
            next
          end

          # Check for repetition pattern: N(...) or (...)
          if input[i] == "(" || (input[i] =~ /\d/ && input[i..-1] =~ /^(\d+)\(/)
            # This is a repetition, find the matching closing paren
            if input[i] == "("
              count_str = ""
              paren_start = i
            else
              count_str = $1
              paren_start = i + count_str.length
            end
            paren_end = find_matching_paren(input, paren_start)

            raise ParseError, "Mismatched parentheses" if paren_end.nil?

            # Check if there's a *[...] after the parenthesis
            next_pos = paren_end + 1
            if next_pos < input.length && input[next_pos] == "*" && input[next_pos + 1] == "["
              # Find the closing bracket
              bracket_end = input.index("]", next_pos + 2)
              raise ParseError, "Mismatched brackets" if bracket_end.nil?
              token = input[i..bracket_end]
              i = bracket_end + 1
            else
              token = input[i..paren_end]
              i = paren_end + 1
            end

            tokens << token
          elsif input[i] =~ /\d/
            # This is a simple segment - match the segment type more precisely
            # Segment types are: w, r (at most 1 character), optionally followed by [Name].
            # (?![a-z]) after the type letter rejects a trailing unrecognized letter (e.g. the
            # "u" in "wu") rather than silently matching just "w" and dropping it — a leftover
            # concern from warrior_timer's original two-letter types (wu/cd), where "w" alone
            # is now a complete, valid match.
            if input[i..-1] =~ /^(\d+(?:\.\d+)?(?::\d+)?m?[wr](?![a-z])(?:@\d+(?:bpm|reps))?(?:\[[^\]]+\])?)/
              tokens << $1
              i += $1.length
            else
              i += 1
            end
          else
            i += 1
          end
        end

        tokens
      end

      def find_matching_paren(input, start_index)
        return nil if input[start_index] != "("

        depth = 1
        i = start_index + 1

        while i < input.length && depth > 0
          case input[i]
          when "("
            depth += 1
          when ")"
            depth -= 1
          end
          i += 1
        end

        depth == 0 ? i - 1 : nil
      end

      def split_respecting_parens(input, delimiter)
        parts = []
        current = ""
        depth = 0

        input.each_char do |char|
          case char
          when "("
            depth += 1
            current << char
          when ")"
            depth -= 1
            raise ParseError, "Mismatched parentheses" if depth < 0
            current << char
          when delimiter
            if depth == 0
              parts << current
              current = ""
            else
              current << char
            end
          else
            current << char
          end
        end

        raise ParseError, "Mismatched parentheses" if depth != 0

        parts << current unless current.empty?
        parts
      end

      def parse_segment(segment)
        # Match patterns like: 30w, 5mw, 1:30w, 30w[Squat], 30w@60bpm, 30w@8reps
        match = segment.match(/^(\d+(?:\.\d+)?(?::\d+)?)(m?)(\w+)(?:@(\d+)(bpm|reps))?(?:\[([^\]]+)\])?$/)

        raise ParseError, "Invalid segment format: #{segment}" unless match

        time_part = match[1]
        minutes_suffix = match[2]
        type_part = match[3]
        pace_number = match[4]
        pace_unit = match[5]
        name_part = match[6]

        type = SEGMENT_TYPES[type_part]
        raise ParseError, "Unknown segment type: #{type_part}" unless type

        duration = parse_duration(time_part, minutes_suffix)

        result = { type: type, duration: duration }
        if pace_number
          result[:bpm] = pace_unit == "reps" ? ((pace_number.to_i + 1) * 60.0 / duration).round : pace_number.to_i
        end
        result[:name] = decode_name(name_part) if name_part
        result
      end

      def parse_duration(time_part, minutes_suffix)
        if time_part.include?(":")
          # Parse m:ss format
          parts = time_part.split(":")
          raise ParseError, "Invalid time format: #{time_part}" if parts.length != 2

          minutes = parts[0].to_i
          seconds = parts[1].to_i
          minutes * 60 + seconds
        elsif minutes_suffix == "m"
          # Parse minutes notation (5m or 1.5m)
          (time_part.to_f * 60).round
        else
          # Parse bare seconds
          time_part.to_i
        end
      end

      # Decode name from URL-friendly format to display format
      # Converts hyphens and underscores to spaces
      def decode_name(name)
        return nil if name.nil? || name.empty?
        name.gsub(/[-_]/, " ")
      end

      # Apply names to work segments in a circuit pattern
      # For example: (30w30r)*[A,B,C] creates 30w[A]30r+30w[B]30r+30w[C]30r
      def apply_names_to_circuit(segments, names, count)
        result = []

        count.times do
          names.each do |name|
            segments.each do |seg|
              new_seg = seg.merge(repetition: true)
              # Only apply names to work segments
              if seg[:type] == :work
                new_seg = new_seg.merge(name: name)
              end
              result << new_seg
            end
          end
        end

        result
      end
    end
  end
end
