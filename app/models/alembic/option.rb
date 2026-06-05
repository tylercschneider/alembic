module Alembic
  class Option < ApplicationRecord
    belongs_to :question

    scope :ordered, -> { order(:position) }
  end
end
