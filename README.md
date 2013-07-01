# Simple API Server in Ruby with Sinatra and Unicorn
## Requirements
 * ruby1.9.x
 * unicorn
 * sinatra

## Installing dependencies
    sudo apt-get install ruby1.9.1 ruby1.9.1-dev rubygems
    sudo gem install unicorn sinatra
  additional dependencies can be installed via "apt-get" or "gem"

## Starting UNICORN
    export PATH=$PATH:/var/lib/gems/1.9.1/bin
    unicorn -E development -l 0.0.0.0:8080

  you can have Unicorn daemonize itself with _"-D"_ flag

      unicorn -E development -D -l 0.0.0.0:8080

## Stopping UNICORN
  to stop your instance or use [CRTL-C] when it's running in foreground

    pkill unicorn

## Accessing Sample API via WebBrowser or CURL
  when running on your local machine use the following URL

    http://localhost:8080

  replace _"localhost"_ with IP/hostname of the machine you've started the service on
