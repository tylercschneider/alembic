module Alembic
  class SummaryVersion < ApplicationRecord
    belongs_to :diagnostic
  end
end
