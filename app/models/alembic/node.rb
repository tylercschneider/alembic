module Alembic
  class Node < ApplicationRecord
    belongs_to :diagnostic
    has_many :build_steps, dependent: :destroy
  end
end
