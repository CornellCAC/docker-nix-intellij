#!/usr/bin/env bash

# Launches IntelliJ IDEA inside a Docker container

# IDEA_IMAGE=${1:-kurron/docker-intellij:latest}

DOCKER=docker
if [ -x "$(command -v nvidia-docker)" ]; then
  DOCKER=nvidia-docker
fi
echo "DOCKER cmd is $DOCKER"

    
DOCKER_GROUP_ID=$(cut -d: -f3 < <(getent group docker))
USER_ID=$(id -u "$(whoami)")
GROUP_ID=$(id -g "$(whoami)")
HOME_DIR=$(cut -d: -f6 < <(getent passwd "${USER_ID}"))
#
# Fixme: this is unsafe if building image within
# the container the container, as you get $HOME_DIR/DevContainerHome/DevContainerHome
#
HOME_DIR_HOST="$HOME_DIR/DevContainerHome"
WORK_DIR=${WORK_DIR:="$HOME_DIR/workspace"}
WORK_DIR_AUX=${WORK_DIR_AUX:="$HOME_DIR/workspaceAux"}
if [ ! -d "${WORK_DIR_AUX}" ]; then
    WORK_DIR_AUX=${WORK_DIR}
fi
echo "WORK_DIR is ${WORK_DIR}"
echo "WORK_DIR_AUX is ${WORK_DIR_AUX}"
#
# Create sync config dir owned by user if not already
#
mkdir -p "${HOME_DIR_HOST}/.config/syncthing"

# Need to give the container access to your windowing system
# Further reading: http://wiki.ros.org/docker/Tutorials/GUI
# and http://gernotklingler.com/blog/howto-get-hardware-accelerated-opengl-support-docker/
export DISPLAY=${DISPLAY:=":0"}
xhost +

PULL="docker pull ${IDEA_IMAGE}"

echo "${PULL}"
"${PULL}"

CMD="${DOCKER} run --detach=true \
                --privileged \
                --group-add ${DOCKER_GROUP_ID} \
                --env HOME=${HOME_DIR} \
                --env DISPLAY \
                --interactive \
                --name DevContainer \
                --net=host \
                --rm \
                --tty \
                --user=${USER_ID}:${GROUP_ID} \
                --volume /usr/local/MATLAB/R2017b:/opt/MATLAB \
                --volume $HOME_DIR_HOST:${HOME_DIR} \
                --volume $WORK_DIR:${WORK_DIR} \
                --volume $WORK_DIR_AUX:${WORK_DIR_AUX} \
                --volume /tmp/.X11-unix:/tmp/.X11-unix \
                --volume /var/run/docker.sock:/var/run/docker.sock \
                --volume /dev/snd:/dev/snd \
                --volume /dev/shm:/dev/shm \
                --volume /etc/machine-id:/etc/machine-id \
                --volume /run/user/$USER_ID/pulse:/run/user/$USER_ID/pulse \
                --volume /var/lib/dbus:/var/lib/dbus \
                --volume $HOME_DIR_HOST/.pulse:$HOME_DIR/.pulse \
                ${IDEA_IMAGE}"

#
# TODO: dbus:
#
#                 --volume /var/run/dbus/system_bus_socket:/run/dbus/system_bus_socket \

echo "$CMD"
CONTAINER=$($CMD)

# Minor post-configuration
sleep 1s
docker exec --user=root "$CONTAINER" groupadd -g "$DOCKER_GROUP_ID" docker
WHO_AM_I=$(docker exec --user="$USER_ID" "$CONTAINER" whoami)
echo "whoami is ${WHO_AM_I}"

#DBUS_UUID=$(docker exec "$CONTAINER" /bin/bash -i -c 'dbus-uuidgen')
#docker exec --user=root "$CONTAINER" bash -c "chmod u+w /etc/machine-id && \
#    echo ${DBUS_UUID} > /etc/machine-id && \
#    chmod u-w /etc/machine-id
#"

docker attach "$CONTAINER"

