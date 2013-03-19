#
# Required libraries
#
require "capistrano/ext/multistage"
require "bundler/capistrano"
require "sidekiq/capistrano"

#
# Load the recipes
#
load "config/recipes/base"
load "config/recipes/nginx"
load "config/recipes/unicorn"

#
# Application Name
#
set :application, "<domain>"

#
# Staged deployment
#
set :stages, %w(production staging)

#
# SCM
#
set :scm, :git
set :deploy_via, :remote_cache
set :repository, "<repo>"

#
# Deployment info
#
set :user, "deploy"
set :use_sudo, false
set :normalize_asset_timestamps, false

#
# SSH Options
#
ssh_options[:forward_agent] = true
ssh_options[:keys] = "<key path>"

#
# Deployment Tasks
#
namespace :deploy do
  desc "create the necessary folders"
  task :create_directories, :role => :web do
    run "mkdir -p #{shared_path}/{config,sockets,uploads}"
  end

  desc "upload and symlink the database config"
  task :link_files, :role => :web do
    put(File.read( "config/database.yml" ),"#{shared_path}/config/database.yml", :via => :scp)
    run "ln -nsf #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
end

#
# Output the rails live log to the console
#
desc "tail log files"
task :tail, :roles => :app do
  run "tail -f #{shared_path}/log/#{rails_env}.log" do |channel, stream, data|
    puts "#{channel[:host]}: #{data}"
    break if stream == :err
  end
end

#
# Get a working irb console from the current rails instance
#
namespace :rails do
  task :console, :roles => :app do
    hostname = find_servers_for_task(current_task).first
    exec "ssh -l #{user} #{hostname} -t 'source ~/.profile && #{current_path}/script/rails c #{rails_env}'"
  end
end

#
# After Hooks
#
after "deploy:setup",           "deploy:create_directories"
after "deploy:setup",           "thin:configure"
after "deploy:setup",           "nginx:configure"
after "deploy:setup",           "unicorn:configure"
after "deploy:finalize_update", "deploy:link_files"
after "deploy:restart",         "unicorn:restart"
after "deploy:restart",         "thin:restart"