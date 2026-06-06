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
        start_label: definition["start_label"]
      )
    end
  end
end
