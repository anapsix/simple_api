# Simple API Server
## Requirements
 * ruby1.9.x
	sudo apt-get install ruby1.9.1 ruby1.9.1-dev rubygems
 * unicorn
	sudo gem install unicorn
 * sinatra
	sudo gem install sinatra

## Starting UNICORN
	export PATH=$PATH:/var/lib/gems/1.9.1/bin
	unicorn -E development -l 0.0.0.0:8080
