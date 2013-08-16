# Simple API Server in Ruby with Sinatra and Unicorn
## Requirements
 * ruby1.9.x
 * unicorn
 * sinatra

## Installing dependencies
    sudo apt-get install ruby1.9.1 ruby1.9.1-dev build-essential
    sudo gem1.9.1 install json unicorn sinatra sinatra-contrib
  additional dependencies can be installed via "apt-get" if available or "gem"

## Starting/Stopping API Server via INIT script
  you can change API port and service name in api\_server.init from it's defaults

     NAME="API Server"
     LISTEN_PORT=8888
     SERVER="thin" # unicorn or thin supported

  start it with

    ./api_server.init start

  stop it with

    ./api_server.init stop

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

## Linux Containers and Docker
  you can launch your API Server in a LXC with Docker
  check out _engage.sh_

    ./engage.sh [start|stop|restart|status]
