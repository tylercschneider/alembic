require "test_helper"
require "ks_blocks/grid"

module KsBlocks
  class GridTest < ActiveSupport::TestCase
    TEXT = BlockType.new(key: :text, name: "Text", width: 6, height: 2)
    HEADING = BlockType.new(key: :heading, name: "Heading", width: 12, height: 1)

    test "adding a block puts it at the given position at its type's starting size" do
      blocks = Grid.add([], TEXT, x: 3, y: 1)

      assert_equal({ "type" => "text", "x" => 3, "y" => 1, "w" => 6, "h" => 2 }, blocks.first.except("id"))
    end

    test "gives each added block its own id" do
      blocks = Grid.add(Grid.add([], TEXT, x: 0, y: 0), TEXT, x: 6, y: 0)

      assert_equal 2, blocks.map { |block| block["id"] }.compact.uniq.size
    end

    test "adding a block with no position places it beside the blocks already on the row" do
      blocks = Grid.add(Grid.add([], TEXT, x: 0, y: 0), TEXT)

      assert_equal [ 6, 0 ], blocks.last.values_at("x", "y")
    end

    test "adding a block with no position places it below when the row has no room" do
      heading = BlockType.new(key: :heading, name: "Heading", width: 12, height: 1)

      blocks = Grid.add(Grid.add([], heading, x: 0, y: 0), TEXT)

      assert_equal [ 0, 1 ], blocks.last.values_at("x", "y")
    end

    test "placing blocks gives each named block its new position and size" do
      blocks = Grid.add([], TEXT, x: 0, y: 0)

      placed = Grid.place(blocks, [ { "id" => blocks.first["id"], "x" => 6, "y" => 3, "w" => 4, "h" => 1 } ])

      assert_equal [ 6, 3, 4, 1 ], placed.first.values_at("x", "y", "w", "h")
    end

    test "removing a block takes only that block off the grid" do
      blocks = Grid.add(Grid.add([], TEXT, x: 0, y: 0), TEXT, x: 6, y: 0)
      kept, removed = blocks.map { |block| block["id"] }

      assert_equal [ kept ], Grid.remove(blocks, removed).map { |block| block["id"] }
    end

    test "placing blocks so they overlap is refused" do
      blocks = Grid.add(Grid.add([], TEXT, x: 0, y: 0), HEADING, x: 0, y: 2)

      assert_raises(InvalidLayout) { Grid.place(blocks, [ { "id" => blocks.last["id"], "x" => 0, "y" => 1, "w" => 12, "h" => 1 } ]) }
    end

    test "placing blocks so they overlap names both blocks in the refusal" do
      KsBlocks.block(:text, name: "Text", width: 6, height: 2)
      KsBlocks.block(:heading, name: "Heading", width: 12, height: 1)
      blocks = Grid.add(Grid.add([], TEXT, x: 0, y: 0), HEADING, x: 0, y: 2)

      assert_equal "Heading overlaps Text", refusal { Grid.place(blocks, [ { "id" => blocks.last["id"], "x" => 0, "y" => 1, "w" => 12, "h" => 1 } ]) }
    end

    test "placing a block past the grid's last column is refused" do
      blocks = Grid.add([], TEXT, x: 0, y: 0)

      assert_raises(InvalidLayout) { Grid.place(blocks, [ { "id" => blocks.first["id"], "x" => 8, "y" => 0, "w" => 6, "h" => 2 } ]) }
    end

    test "placing a block past the grid's last column names the block in the refusal" do
      KsBlocks.block(:text, name: "Text", width: 6, height: 2)
      blocks = Grid.add([], TEXT, x: 0, y: 0)

      assert_equal "Text runs past the grid's last column", refusal { Grid.place(blocks, [ { "id" => blocks.first["id"], "x" => 8, "y" => 0, "w" => 6, "h" => 2 } ]) }
    end

    test "placing a block narrower or shorter than one cell is refused" do
      blocks = Grid.add([], TEXT, x: 0, y: 0)

      assert_raises(InvalidLayout) { Grid.place(blocks, [ { "id" => blocks.first["id"], "x" => 0, "y" => 0, "w" => 6, "h" => 0 } ]) }
    end

    test "placing a block narrower or shorter than one cell names the block in the refusal" do
      KsBlocks.block(:text, name: "Text", width: 6, height: 2)
      blocks = Grid.add([], TEXT, x: 0, y: 0)

      assert_equal "Text must be at least one column wide and one row tall", refusal { Grid.place(blocks, [ { "id" => blocks.first["id"], "x" => 0, "y" => 0, "w" => 6, "h" => 0 } ]) }
    end

    test "adding a block on top of another is refused" do
      assert_raises(InvalidLayout) { Grid.add(Grid.add([], TEXT, x: 0, y: 0), TEXT, x: 3, y: 1) }
    end

    test "adding a block on top of another names both blocks in the refusal" do
      KsBlocks.block(:text, name: "Text", width: 6, height: 2)

      assert_equal "Text overlaps Text", refusal { Grid.add(Grid.add([], TEXT, x: 0, y: 0), TEXT, x: 3, y: 1) }
    end

    test "a block is refused when it runs past the last column of a narrower grid" do
      blocks = Grid.add([], TEXT, x: 0, y: 0)

      assert_raises(InvalidLayout) { Grid.place(blocks, [ { "id" => blocks.first["id"], "x" => 2, "y" => 0, "w" => 6, "h" => 2 } ], columns: 6) }
    end

    test "a block resized below its type's smallest width is refused" do
      limited = BlockType.new(key: :text, name: "Text", width: 6, height: 2, min_width: 4)
      blocks = Grid.add([], limited, x: 0, y: 0)

      assert_raises(InvalidLayout) { Grid.place(blocks, [ { "id" => blocks.first["id"], "x" => 0, "y" => 0, "w" => 3, "h" => 2 } ], types: [ limited ]) }
    end

    test "a block of a type that cannot be resized is refused a new size" do
      fixed = BlockType.new(key: :text, name: "Text", width: 6, height: 2, resizable: false)
      blocks = Grid.add([], fixed, x: 0, y: 0)

      assert_raises(InvalidLayout) { Grid.place(blocks, [ { "id" => blocks.first["id"], "x" => 0, "y" => 0, "w" => 8, "h" => 2 } ], types: [ fixed ]) }
    end

    private

    def refusal
      yield
      nil
    rescue InvalidLayout => error
      error.message
    end
  end
end
