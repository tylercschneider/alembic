module Alembic
  class ApplicationController < Alembic.base_controller.constantize
    layout -> { Alembic.layout }
    helper KeystoneUiHelper
  end
end
