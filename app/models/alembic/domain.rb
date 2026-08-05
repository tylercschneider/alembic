module Alembic
  class Domain < ApplicationRecord
    belongs_to :diagnostic
    has_many :questions, dependent: :nullify
  end
end
