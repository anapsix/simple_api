#!/bin/bash

DEBUG=true

APP_LAUNCH="api_server.init restart"
APP_PORT=8888
EXPOSED_PORT=8888

self_path="$(readlink -e $0)"
APP_DIR="${self_path%%/${self_path##*/}}"
APP_NAME=${APP_DIR##*/}

go_ver=$(go version 2>/dev/null| grep -Po '(\d+\.?)+[^amd64]' || echo missing)
docker_bin=$(which docker || echo missing) # detect docker binary

function docker_missing() {
	echo "Debian version of Docker could be obtained from: https://github.com/dotcloud/docker-debian"
  echo "sudo git clone https://github.com/dotcloud/docker-debian /tmp/docker-debian"
	echo "cd /tmp/docker-debian"
	echo "sudo make VERBOSE=1"
	echo "sudo cp /tmp/docker-debian/bin/docker /usr/local/bin/docker"
}

if [ "${go_ver}" == "missing" ]; then
	echo "You are missing GO.."
	echo "Follow instructions here: http://blog.labix.org/2013/06/15/in-flight-deb-packages-of-go"
	echo ""
	echo "Chances are, you're missing Docker as well.."
	docker_missing
	exit 1
fi

if [ "${docker_bin}" == "missing" ]; then
	echo "Could not find Docker (http://docker.io) in PATH ($PATH), Docker is required to continue.."
	docker_missing
	exit 1
fi
if $DEBUG; then	
	echo "Aplication directory: ${APP_DIR}"
	echo "Aplication name: ${APP_NAME}"
	echo "Aplication name: ${APP_NAME}"
fi

# launch container
sudo $docker_bin run -p ${EXPOSED_PORT}:${APP_PORT} -d -e container=lxc -v ${APP_DIR}:/srv/${APP_NAME} -t ruby1.9/sinatra /srv/${APP_NAME}/${APP_LAUNCH}

