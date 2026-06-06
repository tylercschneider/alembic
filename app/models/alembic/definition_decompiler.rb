module Alembic
  class DefinitionDecompiler
    def initialize(diagnostic)
      @diagnostic = diagnostic
    end

    def load(definition)
      @diagnostic.update!(
        kicker: definition["kicker"],
        headline: definition["headline"],
        blurb: definition["blurb"],
        start_label: definition["start_label"],
        resolver_key: definition.dig("placement", "resolver_key")
      )
    end
  end
end
