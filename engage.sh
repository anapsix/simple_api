#!/bin/bash

DEBUG=true

APP_LAUNCH="api_server.init restart"
APP_PORT=8888
EXPOSED_PORT=8888
DOCKER_IMAGE='ruby1.9/sinatra'

self_path="$(readlink -e $0)"
APP_DIR="${self_path%%/${self_path##*/}}"
APP_NAME=${APP_DIR##*/}

go_ver=$(go version 2>/dev/null | grep -Po '(\d+\.?)+[^amd64]' || echo missing)
docker_bin=$(which docker || echo missing) # detect docker binary

function docker_missing() {
	echo "Debian version of Docker could be obtained from: https://github.com/dotcloud/docker-debian"
  echo "sudo git clone https://github.com/dotcloud/docker-debian /tmp/docker-debian"
	echo "cd /tmp/docker-debian"
	echo "sudo make VERBOSE=1"
	echo "sudo cp /tmp/docker-debian/bin/docker /usr/local/bin/docker"
}

function image_present() {
	image="$1"
	if $docker_bin images | grep -q "${image//./\\.}"; then
		return 0
	fi
	return 1
}


function image_build() {
	image="$1"
	if sudo $docker_bin build -t "${image}" ${APP_DIR};then
		return 0
	else
		return 1
	fi
}

function mount_cgroup() {
	if ! grep '/cgroup' /etc/mtab; then
		echo -e "#mount cgroup\nnone  /cgroup  cgroup  defaults  0 0" | tee -a /etc/fstab >/dev/null
		sudo mount /cgroup && return 0 || return 1
	fi
}

if [ "${docker_bin}" == "missing" ]; then
	echo "Could not find Docker (http://docker.io) in PATH ($PATH), Docker is required to continue.."
	docker_missing
	if [ "${go_ver}" == "missing" ]; then
		echo "You are missing GO.."
		echo "Follow instructions here: http://blog.labix.org/2013/06/15/in-flight-deb-packages-of-go"
	fi
	exit 1
fi

if ! mount_cgroup; then
	echo "Could not mount CGROUP, bailing.."
	exit 1
fi

if ! image_present ${DOCKER_IMAGE}; then
	echo "Required Docker image \"${DOCKER_IMAGE}\" is missing.."
	echo "Gonna try building it.."
	if image_build ${DOCKER_IMAGE}; then
	else
		echo "Image build failed, bailing.."
		exit 1
	if
fi

if $DEBUG; then	
	echo "Aplication directory: ${APP_DIR}"
	echo "Aplication name: ${APP_NAME}"
fi

# launch container
sudo $docker_bin run -p ${EXPOSED_PORT}:${APP_PORT} -d -v ${APP_DIR}:/srv/${APP_NAME} -t ruby1.9/sinatra /srv/${APP_NAME}/${APP_LAUNCH}



# EOF
