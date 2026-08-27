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
        diagnostic.changes_since_version.to_a.map { |change| Change.phrase(change) }
      end

      def flow_details(diagnostic)
        { "title" => diagnostic.title,
          "slug" => diagnostic.slug,
          "summary" => diagnostic.summary,
          "start_label" => diagnostic.start_label,
          "version" => diagnostic.current_definition_version&.number,
          "published" => diagnostic.live_version&.number,
          "definition_url" => edit_manage_flow_definition_path(diagnostic),
          "details_url" => edit_manage_flow_path(diagnostic),
          "history_url" => manage_flow_versions_path(diagnostic) }
      end
    end
  end
end
