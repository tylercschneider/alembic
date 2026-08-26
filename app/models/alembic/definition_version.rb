module Alembic
  class DefinitionVersion < ApplicationRecord
    enum :status, { draft: "draft", live: "live", superseded: "superseded",
                    retired: "retired", withdrawn: "withdrawn" }

    belongs_to :diagnostic

    validates :number, uniqueness: { scope: :diagnostic_id }

    def changes
      changes_captured.to_a
    end

    before_update { raise ActiveRecord::ReadOnlyRecord }
  end
end
