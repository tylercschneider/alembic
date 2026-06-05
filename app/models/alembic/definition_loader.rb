module Alembic
  class DefinitionLoader
    def initialize(definition)
      @definition = definition
    end

    OPTIONAL_COPY_KEYS = %w[headline kicker blurb start_label].freeze

    def build
      Guide.new(slug: @definition["slug"], questions: [], **optional_copy)
    end

    private

    def optional_copy
      @definition.slice(*OPTIONAL_COPY_KEYS).transform_keys(&:to_sym)
    end
  end
end
