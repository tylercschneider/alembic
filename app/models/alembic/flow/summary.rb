module Alembic
  module Flow
    class Summary < ApplicationRecord
      self.table_name = "alembic_flow_summaries"

      belongs_to :flow, class_name: "Alembic::Diagnostic", foreign_key: :diagnostic_id

      validates :number, uniqueness: { scope: :diagnostic_id }

      before_update { raise ActiveRecord::ReadOnlyRecord }
    end
  end
end
