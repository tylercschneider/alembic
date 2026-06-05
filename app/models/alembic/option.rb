module Alembic
  class Option < ApplicationRecord
    belongs_to :question

    validates :value, presence: true

    scope :ordered, -> { order(:position) }
  end
end
