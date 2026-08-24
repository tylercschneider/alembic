module Alembic
  module Flow
    FIELD_TYPES = %i[text string number boolean select list].freeze

    class UnknownFieldType < ArgumentError; end
    class UnknownStepType < KeyError; end
  end
end
