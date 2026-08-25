Alembic::Engine.routes.draw do
  namespace :manage do
    resources :diagnostics, only: [ :index, :create, :show, :edit, :update, :destroy ] do
      resource :definition, only: [ :edit, :update ]

      resource :canvas, only: :show, controller: "canvas" do
        post   "steps",       action: :add_step
        patch  "steps/:step", action: :configure_step
        delete "steps/:step",      action: :remove_step
        patch  "steps/:step/move", action: :move_step
        post   "versions",    action: :cut
        post   "publish",     action: :publish
        post   "undo",        action: :undo
        post   "redo",        action: :redo
        post   "edges",       action: :connect
        delete "edges",       action: :disconnect
      end
    end
  end

  post ":slug/responses", to: "responses#create", as: :diagnostic_responses
  get "responses/:id", to: "responses#show", as: :response
  patch "responses/:id", to: "responses#update"

  get ":slug", to: "diagnostics#show", as: :diagnostic
  get ":slug/step", to: "diagnostics#step", as: :diagnostic_step
end
