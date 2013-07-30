# set path to app that will be used to configure unicorn, 
# note the trailing slash in this example
@service_dir = File.expand_path(File.dirname(File.dirname(__FILE__)))

# get listen port from init script environment
listen_port = ENV['LISTEN_PORT'] || 8888

worker_processes 2
working_directory @service_dir

timeout 30

@log_dir = @service_dir + "/log"
@tmp_dir = @service_dir + "/tmp"

# print out LISTEN_PORT
print  " listening on #{listen_port} .."

# Specify path to socket unicorn listens to, 
# we will use this in our nginx.conf later
#listen "#{@base_dir}tmp/sockets/unicorn.sock", :backlog => 64
listen listen_port, :tcp_nopush => true

# Set process id path
pid "#{@tmp_dir}/unicorn.pid"

# Set log file paths
stderr_path "#{@log_dir}/unicorn.stderr.log"
stdout_path "#{@log_dir}/unicorn.stdout.log"
