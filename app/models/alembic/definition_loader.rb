module Alembic
  class DefinitionLoader
    def initialize(definition)
      @definition = definition
    end

    def build
      Guide.new(slug: @definition["slug"], questions: [])
    end
  end
end
