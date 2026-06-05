module Alembic
  class RuleResult < ApplicationRecord
    belongs_to :rule
    belongs_to :result
  end
end
