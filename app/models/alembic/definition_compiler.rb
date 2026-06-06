module Alembic
  class DefinitionCompiler
    def initialize(diagnostic)
      @diagnostic = diagnostic
    end

    def to_definition
      {
        "slug" => @diagnostic.slug,
        "kicker" => @diagnostic.kicker,
        "headline" => @diagnostic.headline,
        "blurb" => @diagnostic.blurb,
        "start_label" => @diagnostic.start_label
      }
    end
  end
end
