module Alembic
  module Flow
    Output = Data.define(:name, :label, :values) do
      def initialize(name:, label: nil, values: nil)
        super(name: name, label: label.presence || name.to_s.humanize, values: values)
      end

      def values_for(node)
        Array(values&.call(node))
      end
    end
  end
end
