module Alembic
  class ApplicationController < ActionController::Base
    layout -> { Alembic.layout }
    helper KeystoneUiHelper
  end
end
