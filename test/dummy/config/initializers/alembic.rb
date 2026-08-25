Alembic.layout = "application"
Alembic.base_controller = "ApplicationController"

Rails.application.config.to_prepare do
  Steps::Notify.register
end
