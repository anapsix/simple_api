# Simple API Server in Ruby with Sinatra and Thin/Unicorn.
Simple API example with Ruby's Sinatra, Thin/Unicorn, init script, Docker and super-duper self-install script.
## Requirements
 * ruby1.9.x
  + bundler
    - sinatra
    - thin / unicorn / puma

## Optional Requirements
 * lxc container support
 * linux kernel 3.8+ with aufs (3.2 from squeeze-backports, or default wheezy kernel will do)

## Installing dependencies
    sudo apt-get install ruby1.9.1 ruby1.9.1-dev build-essential
    sudo gem install bundle
Then "cd" into where you checked-out code and run `bundle install`. 
Additional dependencies can be installed via "apt-get" (if available) or "gem"

## Starting/Stopping API Server via INIT script
  you can change API port and service name in simple\_api.init and simple\_api.default:

     NAME="simple_api"
     LISTEN_IP="0.0.0.0"  # listen IP, default is 127.0.0.1
     LISTEN_PORT=8888     # listen port, if unset defaults to random in 8000-9000 range
     SERVER="thin"        # thin, unicorn or puma are supported

  start it with

    ./simple_api.init start

  stop it with

    ./simple_api.init stop

## Accessing API via WebBrowser or CURL
  when running on your local machine use the following URL

    http://localhost:8888

  replace _"localhost"_ with IP/hostname of the machine you've started the service on

## Starting/Stopping UNICORN manually
    export PATH=$PATH:/var/lib/gems/1.9.1/bin
    unicorn -E development -l 0.0.0.0:8888

  you can have Unicorn daemonize itself with _"-D"_ flag

      unicorn -E development -D -l 0.0.0.0:8888

  to stop your instance either use _pkill_ or use [CRTL-C] when it's running in foreground

    pkill unicorn

  for examples of starting other server hadnlers (thin, puma), see simple\_api.init source.. 

## Linux Containers and Docker
  you can launch your API Server in a LXC with Docker
  check out _.docker/engage.sh_

    ./engage.sh [start|stop|restart|status]
