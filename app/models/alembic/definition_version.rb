module Alembic
  class DefinitionVersion < ApplicationRecord
    enum :status, { draft: "draft", live: "live", superseded: "superseded",
                    retired: "retired", withdrawn: "withdrawn" }

    belongs_to :diagnostic

    validates :number, uniqueness: { scope: :diagnostic_id }

    def out_of_service?
      retired? || withdrawn?
    end

    def changes
      changes_captured.to_a
    end

    FROZEN = %w[definition number diagnostic_id changes_captured].freeze

    before_update { raise ActiveRecord::ReadOnlyRecord if changed.intersect?(FROZEN) }
  end
end
