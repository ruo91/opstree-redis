CONTAINER_ENGINE ?= podman
NOW_DATE := $(shell date '+%Y%m%d')
REDIS_VERSION ?= v8.10.0-$(NOW_DATE)
REDIS_TOOLS_VERSION ?= v8.10.0-$(NOW_DATE)
REDIS_SENTINEL_VERSION ?= v8.10.0-$(NOW_DATE)
REDIS_EXPORTER_VERSION ?= v1.88.0-$(NOW_DATE)

REDIS_PLATFORM ?= linux/amd64
REDIS_DOCKERFILE ?= Dockerfile.fedora
#REDIS_DOCKERFILE ?= Dockerfile.fedora-io_uring
#REDIS_DOCKERFILE ?= Dockerfile.fedora-redis-search
REDIS_TOOLS_DOCKERFILE ?= Dockerfile.tools-fedora
REDIS_SENTINEL_DOCKERFILE ?= Dockerfile.sentinel-fedora
REDIS_EXPORTER_DOCKERFILE ?= Dockerfile.exporter-fedora

IMG ?= docker.io/ruo91/opstree-redis-fedora:$(REDIS_VERSION)
TOOLS_IMG ?= docker.io/ruo91/opstree-redis-tools-fedora:$(REDIS_TOOLS_VERSION)
EXPORTER_IMG ?= docker.io/ruo91/opstree-redis-exporter-fedora:$(REDIS_EXPORTER_VERSION)
SENTINEL_IMG ?= docker.io/ruo91/opstree-redis-sentinel-fedora:$(REDIS_SENTINEL_VERSION)

build-redis:
	${CONTAINER_ENGINE} build --dns 1.1.1.1 -t ${IMG} -f Dockerfile --build-arg REDIS_VERSION=${REDIS_VERSION} .

push-redis:
	${CONTAINER_ENGINE} push ${IMG}

build-redis-exporter:
	${CONTAINER_ENGINE} build --dns 1.1.1.1 -t ${EXPORTER_IMG} -f Dockerfile.exporter --build-arg REDIS_EXPORTER_VERSION=${REDIS_EXPORTER_VERSION} .

push-redis-exporter:
	${CONTAINER_ENGINE} push ${EXPORTER_IMG}

build-sentinel :
	${CONTAINER_ENGINE} build --dns 1.1.1.1 -t ${SENTINEL_IMG} -f Dockerfile.sentinel --build-arg REDIS_SENTINEL_VERSION=${REDIS_SENTINEL_VERSION} .

push-sentinel :
	${CONTAINER_ENGINE} push ${SENTINEL_IMG}

setup-standalone-server-compose:
	docker-compose -f docker-compose-standalone.yaml up -d

setup-cluster-compose:
	docker-compose -f docker-compose.yaml up -d
	docker-compose exec redis-master-3 /bin/bash -c "/usr/bin/setupMasterSlave.sh"
	docker-compose exec redis-slave-1 /bin/bash -c "/usr/bin/setupMasterSlave.sh"
	docker-compose exec redis-slave-2 /bin/bash -c "/usr/bin/setupMasterSlave.sh"
	docker-compose exec redis-slave-3 /bin/bash -c "/usr/bin/setupMasterSlave.sh"

docker-create:
	${CONTAINER_ENGINE} buildx create --platform "${REDIS_PLATFORM}" --use

docker-build-redis:
	${CONTAINER_ENGINE} buildx build --dns 1.1.1.1 --platform="${REDIS_PLATFORM}" -t ${IMG} -f ${REDIS_DOCKERFILE} .

docker-push-redis:
	${CONTAINER_ENGINE} buildx build --push --platform="${REDIS_PLATFORM}" -t ${IMG} -f ${REDIS_DOCKERFILE} .

docker-build-redis-sentinel:
	${CONTAINER_ENGINE} buildx build --dns 1.1.1.1 --platform="${REDIS_PLATFORM}" -t ${SENTINEL_IMG} -f ${REDIS_SENTINEL_DOCKERFILE} .

docker-push-redis-sentinel:
	${CONTAINER_ENGINE} buildx build --push --platform="${REDIS_PLATFORM}" -t ${SENTINEL_IMG} -f ${REDIS_SENTINEL_DOCKERFILE} .

docker-build-exporter:
	${CONTAINER_ENGINE} buildx build --dns 1.1.1.1 --platform="${REDIS_PLATFORM}" -t ${EXPORTER_IMG} -f ${REDIS_EXPORTER_DOCKERFILE} .

docker-push-exporter:
	${CONTAINER_ENGINE} buildx build --push --platform="${REDIS_PLATFORM}" -t ${EXPORTER_IMG} -f ${REDIS_EXPOTER_DOCKERFILE} .

docker-build-tools:
	${CONTAINER_ENGINE} buildx build --dns 1.1.1.1 --platform="${REDIS_PLATFORM}" -t ${TOOLS_IMG} -f ${REDIS_TOOLS_DOCKERFILE} .

docker-push-tools:
	${CONTAINER_ENGINE} buildx build --push --platform="${REDIS_PLATFORM}" -t ${TOOLS_IMG} -f ${REDIS_TOOLS_DOCKERFILE} .
