# define paths and filenames
pid_file = "log/unicorn.pid"
log_file = "log/unicorn.log"
err_log = "log/unicorn_error.log"
old_pid = pid_file + '.oldbin'

if ENV['RACK_ENV'] == "production"
  stderr_path "log/unicorn.log"
  stdout_path "log/unicorn.log"
end

timeout 30
worker_processes 1
listen 'localhost:3000', :backlog => 1024

pid pid_file

before_fork do |server, worker|
  # zero downtime deploy magic:
  # if unicorn is already running, ask it to start a new process and quit.
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # already done
    end
  end
end
