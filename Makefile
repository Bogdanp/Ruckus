APP_SRC=Ruckus
RKT_SRC=ruckus-core
RKT_FILES=$(shell find ${RKT_SRC} -name '*.rkt' -not -name '.*')
RKT_MAIN_ZO=${RKT_SRC}/compiled/main_rkt.zo

RESOURCES_PATH=${APP_SRC}/res
RUNTIME_NAME=runtime
RUNTIME_PATH=${RESOURCES_PATH}/${RUNTIME_NAME}

CORE_ZO=${RESOURCES_PATH}/core.zo

.PHONY: all
all: ${CORE_ZO} ${APP_SRC}/Backend.swift

.PHONY: clean
clean:
	rm -fr ${RESOURCES_PATH}

${RKT_MAIN_ZO}: ${RKT_FILES}
	./bin/pbraco make -j 16 -v ${RKT_SRC}/main.rkt

${CORE_ZO}: ${RKT_MAIN_ZO}
	mkdir -p ${RESOURCES_PATH}
	rm -fr ${RUNTIME_PATH}
	./bin/pbraco ctool \
	  ++lang north \
	  ++lib racket/runtime-config \
	  --runtime ${RUNTIME_PATH} \
	  --runtime-access ${RUNTIME_NAME} \
	  --mods $@ ${RKT_SRC}/main.rkt

${APP_SRC}/Backend.swift: ${CORE_ZO}
	./bin/pbraco noise-serde-codegen ${RKT_SRC}/main.rkt > $@
