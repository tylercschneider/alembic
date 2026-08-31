module Alembic
  module Flow
    class Runner
      def initialize(document, registry: Flow.registry)
        @document = document.to_h
        @registry = registry
        @digest = Digest.new(Document.new(@document, registry: registry), registry: registry)
      end

      def next_step(state)
        @digest.next_step(named(state))
      end

      private

      def named(state)
        state.transform_keys(&:to_s)
      end
    end
  end
end
