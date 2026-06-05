module Alembic
  class Condition < ApplicationRecord
    belongs_to :subject, polymorphic: true
    belongs_to :tested_question, class_name: "Alembic::Question"
    has_many :condition_options, dependent: :destroy
    has_many :options, through: :condition_options

    def satisfied_by?(answers)
      options.map(&:value).include?(answers[tested_question.key])
    end
  end
end
