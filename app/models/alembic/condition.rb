module Alembic
  class Condition < ApplicationRecord
    belongs_to :question

    def satisfied_by?(answers)
      values.include?(answers[depends_on])
    end
  end
end
