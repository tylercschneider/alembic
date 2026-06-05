module Alembic
  class Question < ApplicationRecord
    belongs_to :diagnostic

    scope :ordered, -> { order(:position) }
  end
end
