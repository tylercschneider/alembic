module Alembic
  class ConditionOption < ApplicationRecord
    belongs_to :condition
    belongs_to :option
  end
end
