module Alembic
  class Question < ApplicationRecord
    belongs_to :diagnostic
    has_many :options, dependent: :destroy
    has_many :conditions, as: :subject, dependent: :destroy

    validates :key, presence: true

    scope :ordered, -> { order(:position) }

    def applies?(answers)
      conditions.all? { |condition| condition.satisfied_by?(answers) }
    end
  end
end
