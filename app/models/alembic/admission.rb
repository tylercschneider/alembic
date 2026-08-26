module Alembic
  module Admission
    def self.of(diagnostic, permitted:)
      raise NotPublished if diagnostic.nil? || diagnostic.live_definition.blank?
      raise NotPermitted unless permitted

      diagnostic
    end
  end
end
