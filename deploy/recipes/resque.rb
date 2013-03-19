set_default(:resque_count) { rails_env == 'production' ? 32 : 1 }
set_default(:resque_queue) { '*' }

namespace :resque do

  %w[start stop restart].each do |command|
    desc "#{command} resque"
    task command, roles: :app do
      case command
        when "start"
          run "cd #{current_path} && RAILS_ENV=#{stage} COUNT=#{resque_count} QUEUE=#{resque_queue} BACKGROUND=yes bundle exec rake environment resque:workers"
        when "stop"
          run "ps -ef | grep [r]esque | awk '{print $2}' | xargs kill -QUIT"
        when "restart"
          stop
      end
    end
  end

end