module Alembic
  module Flow
    class SummaryVersion < ApplicationRecord
      self.table_name = "alembic_flow_summaries"

      belongs_to :flow, class_name: "Alembic::Flow::Definition"

      validates :number, uniqueness: { scope: :flow_id }

      before_update { raise ActiveRecord::ReadOnlyRecord }
    end
  end
end
