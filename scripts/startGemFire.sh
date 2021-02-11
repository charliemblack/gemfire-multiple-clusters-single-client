#!/bin/bash
if [[ $# -eq 0 ]] ; then
  printf "Usage: $0 [number]\n"
  printf "\t where 'number' is the starting port range for GemFire\n"
  printf "\t example: $0 2 - would start GemFire locators at 20334\n"
  exit 1;
fi

PORT_DIGIT=$1
echo "port digit is ${PORT_DIGIT}"
SAVED="`pwd`"
cd "`dirname \"$PRG\"`/.." >&-
APP_HOME="`pwd -P`"
cd "$SAVED" >&-


DEFAULT_LOCATOR_MEMORY="512m"

DEFAULT_SERVER_MEMORY="1024m"

DEFAULT_JVM_OPTS=" --J=-XX:+UseParNewGC"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-Djava.net.preferIPv4Stack=true"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-XX:+UseConcMarkSweepGC"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-XX:CMSInitiatingOccupancyFraction=1"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-XX:+CMSParallelRemarkEnabled"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-XX:+UseCMSInitiatingOccupancyOnly"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-XX:+ScavengeBeforeFullGC"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-XX:+CMSScavengeBeforeRemark"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-XX:+UseCompressedOops"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --mcast-port=0"

HOSTNAME=`hostname -s`
LOCATORS="${HOSTNAME}[${PORT_DIGIT}0334],${HOSTNAME}[${PORT_DIGIT}0335]"


STD_SERVER_ITEMS=" "
STD_SERVER_ITEMS="${STD_SERVER_ITEMS} --locators=${LOCATORS}"
STD_SERVER_ITEMS="${STD_SERVER_ITEMS} --J=-Xmx${DEFAULT_SERVER_MEMORY} --J=-Xms${DEFAULT_SERVER_MEMORY} ${DEFAULT_JVM_OPTS}"


STD_LOCATOR_ITEMS=" "
STD_LOCATOR_ITEMS="${STD_LOCATOR_ITEM} --initial-heap=${DEFAULT_LOCATOR_MEMORY} --max-heap=${DEFAULT_LOCATOR_MEMORY}"
STD_LOCATOR_ITEMS="${STD_LOCATOR_ITEMS} --locators=${LOCATORS}"


function waitForPort {

    (exec 6<>/dev/tcp/${HOSTNAME}/$1) &>/dev/null
    while [[ $? -ne 0 ]]
    do
        echo -n "."
        sleep 1
        (exec 6<>/dev/tcp/${HOSTNAME}/$1) &>/dev/null
    done
}

function launchLocator() {

    mkdir -p ${APP_HOME}/data/${PORT_DIGIT}/locator$1
    pushd ${APP_HOME}/data/${PORT_DIGIT}/locator$1

    gfsh -e "start locator ${STD_LOCATOR_ITEMS} ${DEFAULT_JVM_OPTS} --name=locator$1 --http-service-port=${PORT_DIGIT}007$1 --J=-Dgemfire.jmx-manager-port=${PORT_DIGIT}009$1 --port=${PORT_DIGIT}033$1 --dir=${APP_HOME}/data/${PORT_DIGIT}/locator$1 " &
    popd
}

function launchServer() {

    mkdir -p ${APP_HOME}/data/${PORT_DIGIT}/server${1}
    pushd ${APP_HOME}/data/${PORT_DIGIT}/server${1}

    gfsh -e "start server  --server-port=0  --name=server${1} --dir=${APP_HOME}/data/${PORT_DIGIT}/server${1} ${STD_SERVER_ITEMS}  " &
    popd

}


for i in {4..5}
do
    launchLocator ${i}
    # Stagger the launch so the first locator is the membership coordinator.
    sleep 1
done

# Only need to wait for one locator
waitForPort ${PORT_DIGIT}0334
waitForPort ${PORT_DIGIT}0335


for i in {1..2}
do
    launchServer ${i}
done

wait

gfsh -e "connect --locator=${LOCATORS}" -e "create region --name=cluster${PORT_DIGIT} --type=PARTITION" -e "list members"
echo "Done!"
