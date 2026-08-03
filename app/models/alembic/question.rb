module Alembic
  class Question < ApplicationRecord
    include Positioned

    belongs_to :diagnostic
    # Declared before :options so their condition_options clear first, otherwise
    # destroying a tested question trips the condition_options -> options FK.
    has_many :referencing_conditions, class_name: "Alembic::Condition", foreign_key: :tested_question_id, dependent: :destroy, inverse_of: :tested_question
    has_many :options, dependent: :destroy
    has_many :conditions, as: :subject, dependent: :destroy

    accepts_nested_attributes_for :options, allow_destroy: true

    validates :key, presence: true

    def applies?(answers)
      conditions.all? { |condition| condition.satisfied_by?(answers) }
    end

    private

    def siblings
      diagnostic.questions
    end
  end
end
