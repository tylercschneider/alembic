module Alembic
  class Result < ApplicationRecord
    belongs_to :diagnostic

    enum :slot, { tier: "tier", level: "level", grade: "grade", warning: "warning" }

    validates :key, presence: true

    scope :ordered, -> { order(:position) }
  end
end
