require "test_helper"
require "ks_blocks"

class KsBlocksTest < ActiveSupport::TestCase
  test "declaring a block type puts it in the default registry" do
    KsBlocks.block(:ks_blocks_probe, name: "Probe", width: 4, height: 2)

    assert_includes KsBlocks.registry.block_types, KsBlocks::BlockType.new(key: :ks_blocks_probe, name: "Probe", width: 4, height: 2)
  end

  test "layout data carries the blocks it is given" do
    blocks = [ { "id" => "b1", "type" => "text", "x" => 0, "y" => 0, "w" => 6, "h" => 2 } ]

    assert_equal blocks, KsBlocks.layout_data(blocks)[:blocks]
  end

  test "layout data lists each registered block type's key, name and starting size" do
    KsBlocks.block(:layout_data_probe, name: "Layout probe", width: 3, height: 1)

    listed = KsBlocks.layout_data([])[:block_types].find { |block_type| block_type[:key] == :layout_data_probe }

    assert_equal({ key: :layout_data_probe, name: "Layout probe", width: 3, height: 1 }, listed.slice(:key, :name, :width, :height))
  end

  test "layout data's version changes when the blocks change" do
    before = [ { "id" => "b1", "type" => "text", "x" => 0, "y" => 0, "w" => 6, "h" => 2 } ]
    after = [ { "id" => "b1", "type" => "text", "x" => 6, "y" => 0, "w" => 6, "h" => 2 } ]

    assert_not_equal KsBlocks.layout_data(before)[:version], KsBlocks.layout_data(after)[:version]
  end

  test "declaring a block type for a kind of layout offers it only for that kind" do
    KsBlocks.block(:dashboard_probe, name: "Dashboard probe", width: 3, height: 1, kind: :dashboards)

    assert_equal [], KsBlocks.registry.block_types(kind: :pages).select { |block_type| block_type.key == :dashboard_probe }
  end

  test "layout data lists only the block types of the kind of layout it is for" do
    KsBlocks.block(:layout_data_dashboard_probe, name: "Dashboard probe", width: 3, height: 1, kind: :dashboards)

    assert_equal [], KsBlocks.layout_data([], kind: :pages)[:block_types].select { |block_type| block_type[:key] == :layout_data_dashboard_probe }
  end

  test "a block type carries the sizes it may be resized between" do
    KsBlocks.block(:limited_probe, name: "Limited", width: 6, height: 2, kind: :limits_probe, min_width: 3, max_width: 9, min_height: 1, max_height: 4)

    limited = KsBlocks.registry.block_types(kind: :limits_probe).first

    assert_equal [ 3, 9, 1, 4 ], [ limited.min_width, limited.max_width, limited.min_height, limited.max_height ]
  end
end
