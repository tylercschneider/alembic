module Alembic
  module Flow
    Output = Data.define(:name, :label) do
      def initialize(name:, label: nil)
        super(name: name, label: label.presence || name.to_s.humanize)
      end
    end
  end
end
