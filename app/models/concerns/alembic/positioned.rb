module Alembic
  module Positioned
    extend ActiveSupport::Concern

    included do
      scope :ordered, -> { order(:position) }
    end

    def move_up
      reposition(-1)
    end

    def move_down
      reposition(1)
    end

    private

    def reposition(offset)
      list = siblings.ordered.to_a
      destination = list.index(self) + offset
      return unless destination.between?(0, list.size - 1)

      list.insert(destination, list.delete(self))
      list.each_with_index { |record, spot| record.update!(position: spot + 1) }
    end
  end
end
