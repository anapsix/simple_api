# set path to app that will be used to configure unicorn, 
# note the trailing slash in this example
@service_dir = File.expand_path(File.dirname(File.dirname(__FILE__)))


worker_processes 2
working_directory File.expand_path(File.dirname(@service_dir/..))

timeout 30

@logdir = @service_dir
@tmpdir = @service_dir

# Specify path to socket unicorn listens to, 
# we will use this in our nginx.conf later
#listen "#{@base_dir}tmp/sockets/unicorn.sock", :backlog => 64
listen 8888, :tcp_nopush => true

# Set process id path
pid "#{@service_dir}/unicorn.pid"

# Set log file paths
stderr_path "#{@service_dir}/unicorn.stderr.log"
stdout_path "#{@service_dir}/unicorn.stdout.log"
