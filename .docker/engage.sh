#!/bin/bash

###### begin user configurable options ######

DEBUG=true

APP_LAUNCH="/srv/simple_api/api_server.init restart"
APP_PORT=8888
EXPOSED_PORT=8889
DOCKER_IMAGE='ruby1.9/sinatra'

####### end user configurable options #######

DOCKER_PIDFILE=/var/run/docker.pid
DOCKER_OPTIONS="-d -H="127.0.0.1:4243" -H="unix:///var/run/docker.sock" -api-enable-cors"

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
PURPLE='\e[1;35m'
NC='\e[0m'

error() {
	/bin/echo -e "${RED}ERROR:${NC} $@" >&2
	exit 1
}

warn() {
	/bin/echo -en "${YELLOW}WARNING:${NC} $@" >&2
}

echo -e "${YELLOW}WARNING:${NC} this script requires running few things as root" >&2
echo "We are going to test if you can run sudo now.." >&2
if [ "$(sudo id -u)" != "0" ]; then
  error "sorry, you failed \"sudo\" check, bailing.."
  exit 1
fi

self_path="$(readlink -e $0)"
APP_DIR="${self_path%%/.docker\/${self_path##*/}}"
APP_NAME=${APP_DIR##*/}
DOCKER_DIR="${APP_DIR}/.docker"

REQUIRED_PACKAGES=( curl git make:build-essential tee:coreutils htop )

# checking paths
#echo "self_path=${self_path}"
#echo "derived \${self_path%%/\${self_path##*/}}"
#echo "APP_DIR=${APP_DIR}"
#echo "DOCKER_DIR=${DOCKER_DIR}"
#exit 0

go_ver=$(go version 2>/dev/null | grep -Po '(\d+\.?)+[^amd64]' || echo missing)
#docker_bin=$(which docker || echo missing) # detect docker binary
docker_bin=${DOCKER_DIR}/docker

#
missing_packages=()

check_bin() {
	_bin=${1%:*}
	_package=${1/${1%:*}:}
	[ -n ${_package} ] || _package=${bin}
	which $_bin >/dev/null || missing_packages+=( $_package )
}

for _bin in ${REQUIRED_PACKAGES[@]}; do
	check_bin $_bin
done

mount_cgroup() {
	if ! grep -q '/cgroup' /etc/mtab; then
		echo -e "#mount cgroup\nnone  /cgroup  cgroup  defaults  0 0" | sudo tee -a /etc/fstab >/dev/null
		sudo mount /cgroup 2>/dev/null && return 0 || return 1
	fi
}

install_go() {
	echo "Getting Debian version of GO from: https://github.com/dotcloud/docker-debian" >&2
	curl -s https://godeb.s3.amazonaws.com/godeb-amd64.tar.gz | tar -zx -C /tmp
	sudo /tmp/godeb install
	return $?
}

install_docker() {
	echo "Getting Debian version of Docker from: https://github.com/dotcloud/docker-debian" >&2
	sudo git clone https://github.com/dotcloud/docker-debian.git /tmp/docker-debian
	cd /tmp/docker-debian
	sudo make VERBOSE=1
	RETVAL=$?
	sudo cp /tmp/docker-debian/bin/docker /usr/local/bin/docker
	mount_cgroup
	sudo sysctl net.ipv4.conf.all.forwarding=1
	echo net.ipv4.conf.all.forwarding=1 | sudo tee /etc/sysctl.d/net.ipv4.forwarding.conf 2>/dev/null
	return $RETVAL
}

image_present() {
	_image="$1"
	if sudo $docker_bin images | grep -q "${_image//./\\.}"; then
		return 0
	fi
	return 1
}

image_build() {
	_image="$1"
	if sudo $docker_bin build -t "${_image}" ${DOCKER_DIR}; then
		return 0
	else
		return 1
	fi
}

start_docker() {
	sudo start-stop-daemon --start --background --pidfile $DOCKER_PIDFILE --exec $docker_bin -- $DOCKER_OPTIONS
	RETVAL=$?
	sleep 3
	return $RETVAL
}

stop_docker() {
	sudo start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $DOCKER_PIDFILE --name docker
	return $?
}

status_docker() {
	sudo kill -0 $(cat $DOCKER_PIDFILE 2>/dev/null) 2>/dev/null || sudo kill -0 $(pgrep -x docker) 2>/dev/null
	return $?
}

# install missing packages if any
if [ "${#missing_packages[@]}" -gt 0 ]; then
	warn "Missing packages: ${missing_packages[@]}, going to install them..\n"
	sudo apt-get install -y ${missing_packages[@]}
fi

if [ "${docker_bin}" == "missing" ]; then
	error "Could not find Docker (http://docker.io) in PATH ($PATH), Docker is required to continue, exiting.."
	if ! read -t 5 -n1 -p "Install it automatically? [y/N] " doit; then
		echo "\nIndecisive, eh?" >&2
		exit 1
	fi

	case "$doit" in
	  y|Y)
			if [ "${go_ver}" == "missing" ]; then
				if install_go; then
					echo "GO installed.." >&2
				else
					error "Failed to install GO, try it manually via http://blog.labix.org/2013/06/15/in-flight-deb-packages-of-go"
				fi
			fi
			if install_docker; then
				echo "Docker installed.." >&2
			else
				error "Failed to install Docker, try it manuall via https://github.com/dotcloud/docker-debian"
			fi
		;;
		*)
			warn "Didn't want to do it anyway, bailing..\n"
			exit 1
		;;
	esac
fi

if ! mount_cgroup; then
	error "Could not mount CGROUP, bailing.."
fi

# make sure docker is running
if ! status_docker; then
	warn "Docker is NOT running, trying to start it..\n"
	start_docker || error "failed to start Docker, bailing.."
fi

if ! image_present ${DOCKER_IMAGE}; then
	warn "Required Docker image \"${DOCKER_IMAGE}\" is missing..\n"
	echo "Gonna try building it.." >&2
	if image_build ${DOCKER_IMAGE}; then
		echo "Image ${DOCKER_IMAGE} has been built successfully."
	else
		error "Image build failed, bailing.."
		exit 1
	fi
fi


if $DEBUG; then	
	echo "Aplication name: ${APP_NAME}" >&2
	echo "Aplication directory: ${APP_DIR}" >&2
fi

start_app() {
	instance_id=$(sudo $docker_bin run \
		-d \
		-p ${EXPOSED_PORT}:${APP_PORT} \
		-e container=lxc \
		-v ${APP_DIR}:/srv/${APP_NAME} \
		-t ${DOCKER_IMAGE} \
		${APP_LAUNCH} )
	instance_file="/var/tmp/${APP_NAME}_${EXPOSED_PORT}_${APP_PORT}.id"
	RETVAL=$?
	echo $instance_id > $instance_file
	return $RETVAL
}

stop_app() {
	if [ -r /var/tmp/${APP_NAME}_${EXPOSED_PORT}_${APP_PORT}.id ]; then
		instance_file="/var/tmp/${APP_NAME}_${EXPOSED_PORT}_${APP_PORT}.id"
		instance_id=$(cat $instance_file)
		sudo $docker_bin stop $instance_id
		return $?
	else
		return 1
	fi
}

restart_app() {
	if [ -r /var/tmp/${APP_NAME}_${EXPOSED_PORT}_${APP_PORT}.id ]; then
		instance_id=$(cat /var/tmp/${APP_NAME}_${EXPOSED_PORT}_${APP_PORT}.id)
		sudo $docker_bin restart $instance_id
		return $?
	else
		return 1
	fi
}

check_app_status() {
	if [ -r /var/tmp/${APP_NAME}_${EXPOSED_PORT}_${APP_PORT}.id ]; then
		instance_file="/var/tmp/${APP_NAME}_${EXPOSED_PORT}_${APP_PORT}.id"
		instance_id=$(cat $instance_file)
		if sudo $docker_bin ps | grep -q ${instance_id:-missing_id}; then
			return 0
		else
			rm $instance_file 2>/dev/null
			return 1
		fi
	else
		return 1
	fi
}

case "$1" in
	start)

		if check_app_status; then
			/bin/echo -e "${APP_NAME^^} is ${GREEN}already running${NC} (${instance_id})" >&2
		else
			echo -n "Starting ${APP_NAME^^}: " >&2
			if start_app; then
				/bin/echo -e " ${GREEN}OK${NC} (${instance_id})" >&2
				exit 0
			else
				/bin/echo -e " ${RED}failed${NC}" >&2
				exit 1
			fi
		fi
	;;
	stop)
		if check_app_status; then
			echo -n "Stopping ${APP_NAME^^} (${instance_id}): " >&2
			if stop_app; then
				/bin/echo -e " ${GREEN}OK${NC}" >&2
				exit 0
			else
				/bin/echo -e " ${RED}failed${NC}" >&2
				exit 1
			fi
		else
			/bin/echo -e "${APP_NAME^^} is ${RED}not running${NC}" >&2
			exit 1
		fi
	;;

	restart|force-reload)
		echo -n "Restarting ${APP_NAME^^} (${instance_id}): " >&2
		if restart_app; then
			/bin/echo -e " ${GREEN}OK${NC}" >&2
			exit 0
		else
			/bin/echo -e " ${RED}failed${NC}" >&2
			exit 1
		fi
	;;
	status)
		/bin/echo -en "${APP_NAME^^} is.. " >&2
		if check_app_status; then
			/bin/echo -e " ${GREEN}running${NC} (${instance_id})" >&2
			exit 0
		else
			/bin/echo -e " ${RED}not running${NC}" >&2
			exit 1
		fi
	;;
	*)
		echo "Usage: $0 {start|stop|restart|force-reload|status}" >&2
		exit 1
	;;
esac

exit 0
# EOF