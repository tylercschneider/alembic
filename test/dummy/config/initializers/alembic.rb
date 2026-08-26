Alembic.layout = "application"
Alembic.base_controller = "ApplicationController"
Alembic.visitor_authorization_method = :alembic_visitor_permitted?

Rails.application.config.to_prepare do
  Steps::Notify.register
end
