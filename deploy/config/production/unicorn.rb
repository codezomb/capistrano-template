app_dir = '/opt/apps/<app domain>/'

# Number of workers depends on the environment
worker_processes ENV['RACK_ENV'] == 'production' ? 16 : 4

# Preload the rails app, for faster response
preload_app true

# Timeout
timeout 120

# Pid File
pid "#{app_dir}/shared/pids/unicorn.pid"

# Listen on a Unix data socket
listen "#{app_dir}/shared/sockets/unicorn.sock"

# Log Paths
stderr_path "#{app_dir}/shared/log/unicorn.log"
stdout_path "#{app_dir}/shared/log/unicorn.log"

before_fork do |server, worker|
  # This option works in together with preload_app true setting
  # What is does is prevent the master process from holding
  # the database connection
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  # This allows a new master process to incrementally
  # phase out the old master process with SIGTTOU to avoid a
  # thundering herd (especially in the "preload_app false" case)
  # when doing a transparent upgrade.  The last worker spawned
  # will then kill off the old master process with a SIGQUIT.
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  # Here we are establishing the connection after forking worker processes
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
