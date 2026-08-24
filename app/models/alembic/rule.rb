module Alembic
  class Rule < ApplicationRecord
    include Conditional

    belongs_to :diagnostic
    has_many :rule_results, dependent: :destroy
    has_many :results, through: :rule_results

    scope :ordered, -> { order(:position) }

    def fires?(answers)
      satisfies_conditions?(answers)
    end
  end
end
