set :application, "CloudBurrito"
set :repo_url, "https://github.com/jacksonargo/cloudburrito.git"

# Default branch is :master
#ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/var/www/html/cloudburrito"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, "config/mongoid.yml", "config/secrets.yml"

# Default value for linked_dirs is []
append :linked_dirs, "log"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

set :unicorn_conf, "#{current_path}/config/unicorn.rb"
set :unicorn_pid, "#{shared_path}/log/unicorn.pid"

task :restart_unicorn do
  on roles(:web) do
    execute "if [ -f #{fetch :unicorn_pid} ] && [ -d /proc/$(cat #{fetch :unicorn_pid}) ]; then kill -USR2 $(cat #{fetch :unicorn_pid}); else cd #{current_path} && bundle exec unicorn -c #{fetch :unicorn_conf} -D; fi"
  end
end

after "deploy:published", "restart_unicorn"
