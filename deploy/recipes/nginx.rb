namespace :nginx do

  desc "push the unicorn config file to the server"
  task :configure, :role => :web do
    put(File.read( "config/deploy/configs/#{stage}/nginx.conf" ),"#{shared_path}/config/nginx.conf", :via => :scp)
  end

end