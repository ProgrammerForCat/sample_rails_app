# Unicorn configuration file
worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)
timeout 15
preload_app true

# アプリケーションのルートディレクトリ
app_path = "/var/www/sample_rails_app"

# ソケットファイルのパス
listen "#{app_path}/shared/tmp/sockets/unicorn.sock", backlog: 64, tcp_nopush: false

# PIDファイルのパス
pid "#{app_path}/shared/tmp/pids/unicorn.pid"

# ログファイルのパス
stderr_path "#{app_path}/shared/log/unicorn.stderr.log"
stdout_path "#{app_path}/shared/log/unicorn.stdout.log"

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end 