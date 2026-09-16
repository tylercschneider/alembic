require "digest"
require "json"
require "ks_blocks/registry"

module KsBlocks
  class << self
    def block(key, name:, width:, height:, kind: :blocks, **limits)
      registry.register(BlockType.new(key: key, name: name, width: width, height: height, **limits), kind: kind)
    end

    def layout_data(blocks, kind: :blocks, grid: {})
      { block_types: registry.block_types(kind: kind).map(&:to_h), blocks: blocks, version: version_of(blocks), grid: grid }
    end

    def version_of(blocks)
      Digest::SHA256.hexdigest(JSON.generate(blocks))
    end

    def registry
      @registry ||= Registry.new
    end
  end
end
