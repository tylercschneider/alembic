module Alembic
  module Flow
    class Version < ApplicationRecord
      self.table_name = "alembic_flow_versions"

      enum :status, { draft: "draft", live: "live", superseded: "superseded",
                      retired: "retired", withdrawn: "withdrawn" }

      belongs_to :flow, class_name: "Alembic::Diagnostic", foreign_key: :diagnostic_id

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
end
