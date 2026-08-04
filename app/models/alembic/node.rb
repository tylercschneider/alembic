module Alembic
  class Node < ApplicationRecord
    include Positioned

    belongs_to :diagnostic
    has_many :build_steps, dependent: :destroy

    accepts_nested_attributes_for :build_steps, allow_destroy: true

    private

    def siblings
      diagnostic.nodes
    end
  end
end
