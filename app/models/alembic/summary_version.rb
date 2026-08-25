module Alembic
  class SummaryVersion < ApplicationRecord
    belongs_to :diagnostic

    validates :number, uniqueness: { scope: :diagnostic_id }
  end
end
