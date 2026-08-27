module Alembic
  module Flow
    class Run < ApplicationRecord
      self.table_name = "alembic_flow_runs"

      belongs_to :flow, class_name: "Alembic::Diagnostic", foreign_key: :diagnostic_id
      belongs_to :definition_version
      belongs_to :summary_version, optional: true
      belongs_to :owner, polymorphic: true, optional: true

      def self.start(flow)
        create!(flow: flow, definition_version: flow.live_version,
          summary_version: flow.current_summary_version)
      end

      def record_answer(step_id, value)
        update!(answers: answers.merge(step_id => value))
      end

      def answers
        super.to_h.symbolize_keys
      end

      def pinned_definition
        definition_version.definition.to_h
      end

      def next_step(state)
        digest.next_step(state.transform_keys(&:to_s))
      end

      def walked(state)
        digest.state_on_path(state.transform_keys(&:to_s))
      end

      def digest
        @digest ||= Digest.new(Document.new(pinned_definition))
      end

      def guide
        @guide ||= Alembic::Runner.new(definition_version.definition)
      end

      def summary_of(state)
        return [] unless summary_version

        Alembic::Summary::Report.new(summary_version.summary)
          .results(Alembic::Summary::Run.new(state: state, steps: pinned_steps))
      end

      def discard_last_answer
        last = guide.answers_on_path(answers).keys.last
        update!(answers: answers.except(last)) if last
      end

      private

      def pinned_steps
        Array(definition_version.definition.to_h["nodes"]).index_by { |node| node["id"] }
      end
    end
  end
end
