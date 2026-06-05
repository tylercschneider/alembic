module Alembic
  class Rule < ApplicationRecord
    belongs_to :diagnostic
    has_many :conditions, as: :subject, dependent: :destroy
    has_many :rule_results, dependent: :destroy
    has_many :results, through: :rule_results

    scope :ordered, -> { order(:position) }

    def fires?(answers)
      conditions.all? { |condition| condition.satisfied_by?(answers) }
    end
  end
end
