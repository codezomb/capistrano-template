server "<app domain>", :web, :app, :db, :primary => true
set :deploy_to, "/opt/apps/<app domain>"
set :rails_env, "staging"
set :branch,  "staging"