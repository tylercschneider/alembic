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
  end
end
