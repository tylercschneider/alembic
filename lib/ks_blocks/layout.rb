require "active_support/concern"
require "ks_blocks"
require "ks_blocks/grid"

module KsBlocks
  module Layout
    extend ActiveSupport::Concern

    class_methods do
      def block_layout(column, kind: :blocks, columns: Grid::COLUMNS, row_height: Grid::ROW_HEIGHT, gap: Grid::GAP)
        define_method(:add_block) do |block_type, x: nil, y: nil|
          update!(column => Grid.add(public_send(column), block_type, x: x, y: y, columns: columns))
        end

        define_method(:place_blocks) do |positions, version: nil|
          raise InvalidLayout, "This layout changed since it was last drawn" if version && version != KsBlocks.version_of(public_send(column))

          update!(column => Grid.place(public_send(column), positions, columns: columns, types: KsBlocks.registry.block_types(kind: kind)))
        end

        define_method(:remove_block) do |id|
          update!(column => Grid.remove(public_send(column), id))
        end

        define_method(:block_layout_kind) { kind }

        define_method(:layout_data) do
          KsBlocks.layout_data(public_send(column), kind: kind, grid: { columns: columns, row_height: row_height, gap: gap })
        end
      end
    end
  end
end
