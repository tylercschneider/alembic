module Alembic
  class Transition < ApplicationRecord
    belongs_to :from_question, class_name: "Alembic::Question"
    belongs_to :to_question, class_name: "Alembic::Question"
    has_many :conditions, as: :subject, dependent: :destroy

    def available?(answers)
      conditions.all? { |condition| condition.satisfied_by?(answers) }
    end
  end
end
