Alembic::Engine.routes.draw do
  namespace :manage do
    resources :diagnostics, only: [ :index, :create, :show, :edit, :update, :destroy ] do
      resource :definition, only: [ :edit, :update ]

      resources :steps, only: :index do
        collection do
          patch :reorder
        end
      end
    end
  end

  post ":slug/responses", to: "responses#create", as: :diagnostic_responses
  get "responses/:id", to: "responses#show", as: :response
  patch "responses/:id", to: "responses#update"

  get ":slug", to: "diagnostics#show", as: :diagnostic
  get ":slug/step", to: "diagnostics#step", as: :diagnostic_step
end
