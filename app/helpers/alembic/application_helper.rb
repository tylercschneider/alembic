module Alembic
  module ApplicationHelper
    def alembic_output_lines(value)
      case value
      when Hash then value.map { |name, share| "#{name}: #{share}" }
      when Array then value
      else [ value ]
      end
    end
  end
end
