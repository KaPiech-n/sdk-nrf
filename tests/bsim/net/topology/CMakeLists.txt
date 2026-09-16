# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(topology_bsim_test)

target_sources(app PRIVATE
	src/main.c
	src/test_main.c
)

if(CONFIG_TOPOLOGY_BSIM_ROLE_PINGER)
	target_sources(app PRIVATE src/topology_test.c)
endif()

include(${ZEPHYR_BASE}/samples/net/common/common.cmake)

zephyr_include_directories(
	${BSIM_COMPONENTS_PATH}/libUtilv1/src/
	${BSIM_COMPONENTS_PATH}/libPhyComv1/src/
)
