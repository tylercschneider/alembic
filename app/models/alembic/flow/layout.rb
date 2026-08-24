module Alembic
  module Flow
    class Layout
      COLUMN = 300
      ROW = 150

      def initialize(document)
        @document = document
      end

      def positions
        taken = Hash.new(0)

        depths.to_h do |id, depth|
          row = taken[depth]
          taken[depth] += 1
          [ id, { "x" => row * COLUMN, "y" => depth * ROW } ]
        end
      end

      private

      def depths
        walked = walk_from_entry

        walked.merge(stranded(walked).index_with(next_column(walked)))
      end

      def walk_from_entry
        seen = {}
        frontier = known?(@document.entry) ? [ [ @document.entry, 0 ] ] : []

        until frontier.empty?
          id, depth = frontier.shift
          next if seen.key?(id)

          seen[id] = depth
          @document.edges_from(id).each { |edge| frontier << [ edge.to, depth + 1 ] if known?(edge.to) }
        end

        seen
      end

      def stranded(walked)
        @document.nodes.map(&:id).uniq - walked.keys
      end

      def next_column(walked)
        (walked.values.max || -1) + 1
      end

      def known?(id)
        @document.node(id).present?
      end
    end
  end
end
