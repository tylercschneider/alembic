module Alembic
  class Response < ApplicationRecord
    belongs_to :diagnostic
    belongs_to :definition_version
    belongs_to :summary_version, optional: true
    belongs_to :owner, polymorphic: true, optional: true

    def self.start(diagnostic)
      create!(diagnostic: diagnostic, definition_version: diagnostic.current_definition_version,
        summary_version: diagnostic.current_summary_version)
    end

    def record_answer(question_id, value)
      update!(answers: answers.merge(question_id => value))
    end

    def answers
      super.to_h.symbolize_keys
    end

    def guide
      @guide ||= Runner.new(definition_version.definition)
    end

    def summary_of(state)
      return [] unless summary_version

      Summary::Report.new(summary_version.summary)
        .results(Summary::Run.new(state: state, steps: pinned_steps))
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
