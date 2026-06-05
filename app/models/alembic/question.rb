module Alembic
  class Question < ApplicationRecord
    belongs_to :diagnostic

    validates :key, presence: true

    scope :ordered, -> { order(:position) }
  end
end
