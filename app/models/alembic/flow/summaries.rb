module Alembic
  module Flow
    class Summaries
      def initialize(flow)
        @flow = flow
      end

      def document
        current_version&.summary
      end

      def current_version
        @flow.summary_versions.find_by(number: cursor)
      end

      def record(payload)
        @flow.summary_versions.create!(number: next_number, summary: payload)
          .tap { |version| @flow.update!(summary_cursor: version.number) }
      end

      def any?
        document.present?
      end

      def of(state)
        Summary::Report.new(document).results(Summary::Run.new(state: state, steps: steps_by_id))
      end

      private

      def steps_by_id
        Array(@flow.definition.to_h["nodes"]).index_by { |node| node["id"] }
      end

      def cursor
        @flow.summary_cursor || @flow.summary_versions.pluck(:number).max
      end

      def next_number
        (@flow.summary_versions.maximum(:number) || 0) + 1
      end
    end
  end
end
