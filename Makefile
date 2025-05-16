CONTAINER_ENGINE ?= podman
REDIS_VERSION ?= v8.0.1
REDIS_SENTINEL_VERSION ?= v8.0.1
REDIS_EXPORTER_VERSION ?= v1.72.0

REDIS_PLATFORM ?= linux/amd64
REDIS_DOCKERFILE ?= Dockerfile.ubi9
REDIS_SENTINEL_DOCKERFILE ?= Dockerfile.sentinel-ubi9
REDIS_EXPORTER_DOCKERFILE ?= Dockerfile.exporter-ubi9

IMG ?= quay.io/opstree/redis-ubi9:$(REDIS_VERSION)
EXPORTER_IMG ?= quay.io/opstree/redis-exporter-ubi9:$(REDIS_EXPORTER_VERSION)
SENTINEL_IMG ?= quay.io/opstree/redis-sentinel-ubi9:$(REDIS_SENTINEL_VERSION)

build-redis:
	${CONTAINER_ENGINE} build -t ${IMG} -f Dockerfile --build-arg REDIS_VERSION=${REDIS_VERSION} .

push-redis:
	${CONTAINER_ENGINE} push ${IMG}

build-redis-exporter:
	${CONTAINER_ENGINE} build -t ${EXPORTER_IMG} -f Dockerfile.exporter --build-arg REDIS_EXPORTER_VERSION=${REDIS_EXPORTER_VERSION} .

push-redis-exporter:
	${CONTAINER_ENGINE} push ${EXPORTER_IMG}

build-sentinel :
	${CONTAINER_ENGINE} build -t ${SENTINEL_IMG} -f Dockerfile.sentinel --build-arg REDIS_SENTINEL_VERSION=${REDIS_SENTINEL_VERSION} .

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
	${CONTAINER_ENGINE} buildx build --platform="${REDIS_PLATFORM}" -t ${IMG} -f ${REDIS_DOCKERFILE} .

docker-push-redis:
	${CONTAINER_ENGINE} buildx build --push --platform="${REDIS_PLATFORM}" -t ${IMG} -f ${REDIS_DOCKERFILE} .

docker-build-redis-sentinel:
	${CONTAINER_ENGINE} buildx build --platform="${REDIS_PLATFORM}" -t ${SENTINEL_IMG} -f ${REDIS_SENTINEL_DOCKERFILE} .

docker-push-redis-sentinel:
	${CONTAINER_ENGINE} buildx build --push --platform="${REDIS_PLATFORM}" -t ${SENTINEL_IMG} -f ${REDIS_SENTINEL_DOCKERFILE} .

docker-build-exporter:
	${CONTAINER_ENGINE} buildx build --platform="${REDIS_PLATFORM}" -t ${EXPORTER_IMG} -f ${REDIS_EXPOTER_DOCKERFILE} .

docker-push-exporter:
	${CONTAINER_ENGINE} buildx build --push --platform="${REDIS_PLATFORM}" -t ${EXPORTER_IMG} -f ${REDIS_EXPOTER_DOCKERFILE} .
