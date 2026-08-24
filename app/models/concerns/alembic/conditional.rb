module Alembic
  module Conditional
    extend ActiveSupport::Concern

    included do
      has_many :conditions, as: :subject, dependent: :destroy
    end

    def satisfies_conditions?(answers)
      conditions.all? { |condition| condition.satisfied_by?(answers) }
    end
  end
end
