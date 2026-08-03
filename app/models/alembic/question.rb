module Alembic
  class Question < ApplicationRecord
    belongs_to :diagnostic
    # Declared before :options so their condition_options clear first, otherwise
    # destroying a tested question trips the condition_options -> options FK.
    has_many :referencing_conditions, class_name: "Alembic::Condition", foreign_key: :tested_question_id, dependent: :destroy, inverse_of: :tested_question
    has_many :options, dependent: :destroy
    has_many :conditions, as: :subject, dependent: :destroy

    accepts_nested_attributes_for :options, allow_destroy: true

    validates :key, presence: true

    scope :ordered, -> { order(:position) }

    def move_up
      reposition(-1)
    end

    def move_down
      reposition(1)
    end

    def applies?(answers)
      conditions.all? { |condition| condition.satisfied_by?(answers) }
    end

    private

    def reposition(offset)
      siblings = diagnostic.questions.ordered.to_a
      destination = siblings.index(self) + offset
      return unless destination.between?(0, siblings.size - 1)

      siblings.insert(destination, siblings.delete(self))
      siblings.each_with_index { |question, spot| question.update!(position: spot + 1) }
    end
  end
end
