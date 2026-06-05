module Alembic
  class Question < ApplicationRecord
    belongs_to :diagnostic
    has_many :options, dependent: :destroy

    validates :key, presence: true

    scope :ordered, -> { order(:position) }
  end
end
