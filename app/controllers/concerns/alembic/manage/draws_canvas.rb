module Alembic
  module Manage
    module DrawsCanvas
      extend ActiveSupport::Concern

      private

      def canvas_payload(diagnostic)
        Flow::Canvas.new(canvas_document(diagnostic)).to_h
          .merge("undoable" => diagnostic.undoable?, "redoable" => diagnostic.redoable?,
                 "changes" => listed_changes(diagnostic), "flow" => flow_details(diagnostic))
      end

      def canvas_document(diagnostic)
        Flow::Document.new(diagnostic.document || diagnostic.definition || {})
      end

      def listed_changes(diagnostic)
        diagnostic.changes_since_version.to_a.map { |change| change.except("before") }
      end

      def flow_details(diagnostic)
        { "title" => diagnostic.title.presence || diagnostic.slug,
          "version" => diagnostic.current_definition_version&.number,
          "published" => diagnostic.published_version&.number,
          "definition_url" => edit_manage_diagnostic_definition_path(diagnostic),
          "details_url" => edit_manage_diagnostic_path(diagnostic) }
      end
    end
  end
end
