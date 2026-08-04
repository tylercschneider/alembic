module Alembic
  class BuildStep < ApplicationRecord
    include Positioned

    belongs_to :node

    private

    def siblings
      node.build_steps
    end
  end
end
