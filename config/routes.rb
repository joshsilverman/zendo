Zendo::Application.routes.draw do

  resources :authentications

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
  
  #devise
  devise_for :users, :timeout_in => 7.days,
    :controllers => {:registrations => 'registrations'} #, :sessions => 'sessions'}

  #tags
  get "tag/index" # ???
  match "/explore" => "tags#index" #** public **#
  match "/tags/create" => "tags#create"
  match "/tags/create_and_assign" => "tags#create"
  match "/tags/update_tags_name"

  # documents
  match "/documents/create/:tag_id" => "documents#create"
  match "/documents/update_tag"
  match "/documents/update_privacy"
  match "/documents/update_document_name"
  match "/documents/:id" => "documents#edit", :read_only => true
  resources :documents, :only => [:edit, :update, :destroy]

  # reviewer
  match "/review/:id" => "documents#review" #** public **#
  match "/review/dir/:id" => "tags#review" #** public **#
  match "/mems/update/:id/:confidence/:importance" => "mems#update"
  resources :lines, :only => [:update]
  
  # organizer
  resources :tags, :only => [:destroy, :create, :update]
  match "/tags/get_tags_json" => "tags#get_tags_json"

  # home page
  match "users/welcome" => "users#home"
  root :to => "users#home"

  # authentications
  match '/auth/:provider/callback' => 'authentications#create'
  match '/users/get_email' => 'users#get_email'
  resources :authentications

  # ajax sign in
  match "users/simple_sign_in" => "users#simple_sign_in"

  #abingo dashboard

  # match '/abingo(/:action(/:id))' => 'abingo_dash', :as => :abingo

#  namespace :user do
#    root :controller => 'users', :action => 'home'
#  end

  # catch-all route for static pages
  Zendo::Application.routes.draw do |map|
    map.connect ':action', :controller => "static"
    #map.abingoTest "/abingo/:action/:id", :controller=> :abingo_dash
  end
end
