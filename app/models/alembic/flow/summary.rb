module Alembic
  module Flow
    class Summary < ApplicationRecord
      self.table_name = "alembic_flow_summaries"

      belongs_to :flow, class_name: "Alembic::Flow::Flow"

      validates :number, uniqueness: { scope: :flow_id }

      before_update { raise ActiveRecord::ReadOnlyRecord }
    end
  end
end
