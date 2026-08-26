module Alembic
  module Admission
    def self.of(diagnostic, permitted:)
      raise NotPublished if diagnostic.nil? || diagnostic.published_definition.blank?
      raise NotPermitted unless permitted

      diagnostic
    end
  end
end
