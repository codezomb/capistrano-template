set_default(:unicorn_pid) { "#{shared_path}/pids/unicorn.pid" }
set_default(:unicorn_config) { "#{shared_path}/config/unicorn.rb" }

namespace :unicorn do

  desc "push the unicorn config file to the server"
  task :configure, :role => :web do
    put(File.read( "config/deploy/configs/#{stage}/unicorn.rb" ),"#{shared_path}/config/unicorn.rb", :via => :scp)
  end

  %w[start stop restart].each do |command|
    desc "#{command} unicorn"
    task command, roles: :app do
      case command
        when "start"
          run "cd #{current_path} && bundle exec unicorn -c #{unicorn_config} -D -E #{stage}"
        when "stop"
          run "if [ -e #{unicorn_pid} ]; then kill -QUIT `cat #{unicorn_pid}`; fi"
        when "restart"
          stop
          start
      end
    end
  end

end