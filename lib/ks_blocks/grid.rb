require "securerandom"
require "ks_blocks/block_type"
require "ks_blocks"

module KsBlocks
  class InvalidLayout < StandardError; end

  module Grid
    COLUMNS = 12
    ROW_HEIGHT = 60
    GAP = 10

    module_function

    def add(blocks, block_type, x: nil, y: nil, columns: COLUMNS)
      x, y = first_open_place(blocks, block_type, columns) if x.nil? || y.nil?
      added = { "id" => SecureRandom.uuid, "type" => block_type.key.to_s, "x" => x, "y" => y, "w" => block_type.width, "h" => block_type.height }
      (blocks + [ added ]).tap { |arranged| refuse_unfit(arranged, [ added["id"] ], columns, []) }
    end

    def place(blocks, positions, columns: COLUMNS, types: [])
      placed = positions.index_by { |position| position["id"] }
      blocks.map { |block| block.merge(placed.fetch(block["id"], {}).slice("x", "y", "w", "h")) }.tap { |arranged| refuse_unfit(arranged, placed.keys, columns, types, blocks.index_by { |block| block["id"] }) }
    end

    def refuse_unfit(blocks, moved_ids, columns, types = [], blocks_before = {})
      blocks.select { |block| moved_ids.include?(block["id"]) }.each do |moved|
        block_type = types.find { |registered| registered.key.to_s == moved["type"] }
        refuse_resizing(moved, block_type, blocks_before[moved["id"]])
        refuse_outside_limits(moved, block_type)
        raise InvalidLayout, "#{named(moved)} must be at least one column wide and one row tall" if moved["w"] < 1 || moved["h"] < 1
        raise InvalidLayout, "#{named(moved)} runs past the grid's last column" if moved["x"] + moved["w"] > columns
      end
      refuse_overlaps(blocks, moved_ids)
    end

    def refuse_overlaps(blocks, moved_ids)
      blocks.select { |block| moved_ids.include?(block["id"]) }.each do |moved|
        covered = blocks.find { |other| other["id"] != moved["id"] && overlaps?(other, moved["x"], moved["y"], moved["w"], moved["h"]) }
        raise InvalidLayout, "#{named(moved)} overlaps #{named(covered)}" if covered
      end
    end

    def refuse_resizing(block, block_type, before)
      return if block_type.nil? || block_type.resizable || before.nil?
      return if block["w"] == before["w"] && block["h"] == before["h"]

      raise InvalidLayout, "#{named(block)} cannot be resized"
    end

    def refuse_outside_limits(block, block_type)
      return unless block_type

      raise InvalidLayout, "#{named(block)} cannot be narrower than #{block_type.min_width} columns" if block["w"] < block_type.min_width
      raise InvalidLayout, "#{named(block)} cannot be shorter than #{block_type.min_height} rows" if block["h"] < block_type.min_height
      raise InvalidLayout, "#{named(block)} cannot be wider than #{block_type.max_width} columns" if block_type.max_width && block["w"] > block_type.max_width
      raise InvalidLayout, "#{named(block)} cannot be taller than #{block_type.max_height} rows" if block_type.max_height && block["h"] > block_type.max_height
    end

    def named(block)
      KsBlocks.registry.block_types.find { |block_type| block_type.key.to_s == block["type"] }&.name || block["type"]
    end

    def remove(blocks, id)
      blocks.reject { |block| block["id"] == id }
    end

    def first_open_place(blocks, block_type, columns)
      (0..).each do |y|
        (0..columns - block_type.width).each do |x|
          return [ x, y ] unless blocks.any? { |block| overlaps?(block, x, y, block_type.width, block_type.height) }
        end
      end
    end

    def overlaps?(block, x, y, width, height)
      x < block["x"] + block["w"] && block["x"] < x + width && y < block["y"] + block["h"] && block["y"] < y + height
    end
  end
end
