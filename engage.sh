#!/bin/bash

###### begin user configurable options ######

DEBUG=true

APP_LAUNCH="api_server.init restart"
APP_PORT=8888
EXPOSED_PORT=8888
DOCKER_IMAGE='ruby1.9/sinatra'

####### end user configurable options #######

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
PURPLE='\e[1;35m'
NC='\e[0m'

echo -e "${YELLOW}WARNING:${NC} this script requires running few things root"
echo "We are going to test if you can run sudo now.."
if [ "$(sudo id -u)" != "0" ]; then
  echo -e "${RED}FATAL:${NC} sorry, you failed \"sudo\" check, bailing.."
  exit 1
fi

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

function start_app() {
	instance_id=$(sudo $docker_bin run -p ${EXPOSED_PORT}:${APP_PORT} -d -v ${APP_DIR}:/srv/${APP_NAME} -t ruby1.9/sinatra /srv/${APP_NAME}/${APP_LAUNCH})
	return $?
}

function stop_app() {
	instance_id=$(sudo $docker_bin run -p ${EXPOSED_PORT}:${APP_PORT} -d -v ${APP_DIR}:/srv/${APP_NAME} -t ruby1.9/sinatra /srv/${APP_NAME}/${APP_LAUNCH})
	return $?
}

function restart_app() {
	instance_id=$(sudo $docker_bin run -p ${EXPOSED_PORT}:${APP_PORT} -d -v ${APP_DIR}:/srv/${APP_NAME} -t ruby1.9/sinatra /srv/${APP_NAME}/${APP_LAUNCH})
	return $?
}

case "$1" in
  start)
	echo -n "Starting ${APP_NAME}: " >&2
	if start_app
		/bin/echo -e " ${GREEN}OK${NC}" >&2
	else
		/bin/echo -e " ${RED}failed${NC}" >&2
	fi
	;;
  stop)
	echo -n "Stopping ${APP_NAME}: " >&2
	if stop_app
		/bin/echo -e " ${GREEN}OK${NC}" >&2
	else
		/bin/echo -e " ${RED}failed${NC}" >&2
	fi
	rm -f $PIDFILE
	;;

  restart|force-reload)
	#
	#	If the "reload" option is implemented, move the "force-reload"
	#	option to the "reload" entry above. If not, "force-reload" is
	#	just the same as "restart".
	#
	echo -n "Stopping ${APP_NAME}: " >&2
	if stop_app
		/bin/echo -e " ${GREEN}OK${NC}" >&2
	else
		/bin/echo -e " ${RED}failed${NC}" >&2
	fi
	;;
  status)
	if check_app_status
		/bin/echo -e " ${GREEN}OK${NC}" >&2
	else
		/bin/echo -e " ${RED}failed${NC}" >&2
	fi
	;;
  *)
	echo "Usage: $0 {start|stop|restart|force-reload|status}" >&2
	exit 1
	;;
esac

# EOF

# EOF
