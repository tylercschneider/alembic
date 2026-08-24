module Alembic
  class DefinitionDocument
    def initialize(definition)
      @definition = definition
    end

    def reorder(ids)
      @definition.merge("questions" => ids.filter_map { |id| question(id) })
    end

    private

    def question(id)
      Array(@definition["questions"]).find { |question| question["id"] == id }
    end
  end
end
