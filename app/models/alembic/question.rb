module Alembic
  class Question < ApplicationRecord
    belongs_to :diagnostic
    has_many :options, dependent: :destroy
    has_many :conditions, as: :subject, dependent: :destroy

    accepts_nested_attributes_for :options, allow_destroy: true

    validates :key, presence: true

    scope :ordered, -> { order(:position) }

    def applies?(answers)
      conditions.all? { |condition| condition.satisfied_by?(answers) }
    end
  end
end
