module Alembic
  class Domain < ApplicationRecord
    belongs_to :diagnostic
  end
end
