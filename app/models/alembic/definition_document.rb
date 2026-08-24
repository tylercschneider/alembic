module Alembic
  class DefinitionDocument
    def initialize(definition)
      @definition = definition
    end

    def reorder(ids)
      ordered = ids.filter_map { |id| question(id) }
      @definition.merge("questions" => ordered + (questions - ordered))
    end

    private

    def questions
      Array(@definition["questions"])
    end

    def question(id)
      questions.find { |question| question["id"] == id }
    end
  end
end
