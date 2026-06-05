module Alembic
  class Result < ApplicationRecord
    belongs_to :diagnostic

    enum :slot, { tier: "tier", level: "level", grade: "grade", warning: "warning" }

    scope :ordered, -> { order(:position) }
  end
end
