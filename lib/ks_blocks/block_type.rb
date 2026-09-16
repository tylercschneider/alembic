module KsBlocks
  BlockType = Data.define(:key, :name, :width, :height, :min_width, :max_width, :min_height, :max_height, :resizable) do
    def initialize(key:, name:, width:, height:, min_width: 1, max_width: nil, min_height: 1, max_height: nil, resizable: true)
      super
    end
  end
end
