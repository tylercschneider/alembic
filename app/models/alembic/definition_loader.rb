module Alembic
  class DefinitionLoader
    def initialize(definition)
      @definition = definition
    end

    def build
      Guide.new(slug: @definition["slug"], questions: [], headline: @definition["headline"], kicker: @definition["kicker"], blurb: @definition["blurb"])
    end
  end
end
