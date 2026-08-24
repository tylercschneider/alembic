module Alembic
  class Question < ApplicationRecord
    include Positioned
    include Conditional

    belongs_to :diagnostic
    belongs_to :domain, optional: true
    # Declared before :options so their condition_options clear first, otherwise
    # destroying a tested question trips the condition_options -> options FK.
    has_many :referencing_conditions, class_name: "Alembic::Condition", foreign_key: :tested_question_id, dependent: :destroy, inverse_of: :tested_question
    has_many :options, dependent: :destroy

    accepts_nested_attributes_for :options, allow_destroy: true

    validates :key, presence: true

    def applies?(answers)
      satisfies_conditions?(answers)
    end

    private

    def siblings
      diagnostic.questions
    end
  end
end
