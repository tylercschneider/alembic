module Alembic
  class Transition < ApplicationRecord
    include Conditional

    belongs_to :from_question, class_name: "Alembic::Question"
    belongs_to :to_question, class_name: "Alembic::Question"

    def available?(answers)
      satisfies_conditions?(answers)
    end
  end
end
