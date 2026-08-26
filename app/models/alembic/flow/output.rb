module Alembic
  module Flow
    Output = Data.define(:name, :label, :type, :values) do
      def initialize(name:, label: nil, type: :string, values: nil)
        raise UnknownOutputType, "#{type} is not one of #{OUTPUT_TYPES.join(', ')}" unless OUTPUT_TYPES.include?(type)

        super(name: name, label: label.presence || name.to_s.humanize, type: type, values: values)
      end

      def values_for(node)
        Array(values.respond_to?(:call) ? values.call(node) : values)
      end
    end
  end
end
