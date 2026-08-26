module Alembic
  module Admission
    def self.of(diagnostic, permitted:)
      raise NotPublished if diagnostic.nil? || diagnostic.live_definition.blank?
      raise NotPermitted unless permitted && diagnostic.available?

      diagnostic
    end

    def self.of_run(run, permitted: true)
      raise Withdrawn if run.definition_version.withdrawn?
      raise NotPermitted unless permitted && run.diagnostic.available?

      run
    end
  end
end
