module Alembic
  class Response < ApplicationRecord
    belongs_to :diagnostic
    belongs_to :definition_version
    belongs_to :owner, polymorphic: true, optional: true

    def self.start(diagnostic)
      create!(diagnostic: diagnostic, definition_version: diagnostic.current_definition_version)
    end

    def record_answer(question_id, value)
      update!(answers: answers.merge(question_id => value))
    end

    def answers
      super.to_h.symbolize_keys
    end

    def guide
      DefinitionLoader.new(definition_version.definition).build
    end

    def discard_last_answer
      last = last_answered_question
      update!(answers: answers.except(last.id)) if last
    end

    private

    def last_answered_question
      guide.applicable_questions(answers).select { |question| answers.key?(question.id) }.last
    end
  end
end
