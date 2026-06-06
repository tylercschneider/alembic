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
        "start_label" => @diagnostic.start_label,
        "placement" => { "resolver_key" => @diagnostic.resolver_key }
      }
    end
  end
end
