module Alembic
  class DefinitionVersion < ApplicationRecord
    belongs_to :diagnostic

    validates :number, uniqueness: { scope: :diagnostic_id }

    def readonly?
      persisted?
    end
  end
end
