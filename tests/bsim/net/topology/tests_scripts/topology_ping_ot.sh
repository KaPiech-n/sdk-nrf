#!/usr/bin/env bash
# Copyright (c) 2026 Nordic Semiconductor ASA
# SPDX-License-Identifier: Apache-2.0

source ${ZEPHYR_BASE}/tests/bsim/sh_common.source

# BabbleSim counterpart of test-fw test_form_topology_and_ping_cli (ICMP subset).
# Maps to tests/topology/tests_topology.py::test_form_topology_and_ping_cli

simulation_id="${BOARD_TS}_topology_ping_ot"
verbosity_level=2

EXECUTE_TIMEOUT=120

cd ${BSIM_OUT_PATH}/bin

Execute ./bs_${BOARD_TS}_tests_bsim_net_topology_prj_conf_overlay-pinger_conf \
	-v=${verbosity_level} -s=${simulation_id} -start_offset=2e6 -d=0 -RealEncryption=1 \
	-testid=topology_ping

Execute ./bs_${BOARD_TS}_tests_bsim_net_topology_prj_conf_overlay-responder_conf \
	-v=${verbosity_level} -s=${simulation_id} -d=1 -RealEncryption=1

Execute ./bs_2G4_phy_v1 -v=${verbosity_level} -s=${simulation_id} \
	-D=2 -sim_length=50e6 -argschannel -at=40 -argsmain $@

wait_for_background_jobs
