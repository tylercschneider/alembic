module Alembic
  class DefinitionVersion < ApplicationRecord
    belongs_to :diagnostic

    validates :number, uniqueness: { scope: :diagnostic_id }

    def changes
      changes_captured.to_a
    end

    before_update { raise ActiveRecord::ReadOnlyRecord }
  end
end
