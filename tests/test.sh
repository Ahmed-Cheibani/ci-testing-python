#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

ARGS=("$@")


cleanup () {
	# stop test containers
	docker-compose -p ${ARGS[2]} -f ${ARGS[3]}/docker-compose.yml stop

	# remove test containers
	docker-compose -p ${ARGS[2]} -f ${ARGS[3]}/docker-compose.yml rm --force -v
}


trap 'cleanup ; printf "${RED}Tests Failed For Unexpected Reasons${NC}\n"' HUP INT QUIT PIPE TERM

# build and run
echo "Building and then Running Test Containers"
docker-compose -p "$3" -f "$4"/docker-compose.yml build && \
docker-compose -p "$3" -f "$4"/docker-compose.yml up -d

if [ $? -ne 0 ] ; then
  printf "${RED}Docker Compose Failed${NC}\n"
  exit -1
fi

DOCKER_TEST_CONTAINER="$3_$1_$2_tester_1"
TEST_EXIT_CODE=$(docker wait "$DOCKER_TEST_CONTAINER")

echo "Test Containers Logs"
docker logs "$DOCKER_TEST_CONTAINER"

if [ -z ${TEST_EXIT_CODE+x} ] || [ "$TEST_EXIT_CODE" -ne 0 ] ; then
  printf "${RED}Tests Failed${NC} - Exit Code: $TEST_EXIT_CODE\n"
else
  printf "${GREEN}Tests Passed${NC}\n"
fi

# cleanup test setup and containers
echo "Cleaning up test containers"
cleanup

exit $TEST_EXIT_CODE