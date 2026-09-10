#!/usr/bin/env bash
# KRKNWK-22421: Run or build BabbleSim net tests on NCS + nrf52_bsim.
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#
# Usage:
#   run_bsim_test.sh list
#   run_bsim_test.sh run <scenario>
#   run_bsim_test.sh build <scenario>
#
# Scenarios:
#   echo-openthread   upstream net.sockets.echo_test.openthread (runnable)
#   echo-802154       upstream net.sockets.echo_test.802154 (runnable)
#   topology          net.topology.ping.openthread (runnable)
#   coap              build-only until tests/bsim/net/coap exists
#   dataset           build-only until tests/bsim/net/dataset exists

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NRF_BASE="$(cd "${SCRIPT_DIR}/../.." && pwd)"
NCS_BASE="$(cd "${NRF_BASE}/.." && pwd)"

: "${ZEPHYR_BASE:=${NCS_BASE}/zephyr}"
: "${BSIM_OUT_PATH:=${NCS_BASE}/tools/bsim}"
: "${BSIM_COMPONENTS_PATH:=${BSIM_OUT_PATH}/components}"

export ZEPHYR_BASE BSIM_OUT_PATH BSIM_COMPONENTS_PATH
export BOARD="${BOARD:-nrf52_bsim/native}"
export LD_LIBRARY_PATH="${BSIM_OUT_PATH}/lib:${LD_LIBRARY_PATH:-}"

OT_BASE_CONF="${SCRIPT_DIR}/nrf52_bsim_openthread.conf"
OT_802154_CONF="${SCRIPT_DIR}/nrf52_bsim_ieee802154.conf"

ot_conf() {
	local scenario="${1}"
	echo "${OT_BASE_CONF};${SCRIPT_DIR}/nrf52_bsim_${scenario}.conf"
}

usage() {
	cat <<EOF
Usage: $0 list
       $0 run <scenario>
       $0 build <scenario>

Scenarios:
  echo-openthread   Run Zephyr echo test (OpenThread)
  echo-802154       Run Zephyr echo test (802.15.4)
  topology          Run Zephyr 2-node OT ping test (maps test_form_topology_and_ping_cli)
  coap              Build NCS CoAP server + client for bsim test (run script TBD)
  dataset           Build NCS CLI for dataset bsim test (run script TBD)
EOF
}

require_bsim() {
	if [ ! -x "${BSIM_OUT_PATH}/bin/bs_2G4_PHY_v1" ] && \
	   [ ! -x "${BSIM_OUT_PATH}/bin/bs_2G4_phy_v1" ]; then
		echo "Build BabbleSim first: cd ${BSIM_OUT_PATH} && make everything" >&2
		exit 1
	fi
}

require_conf() {
	local path="${1}"
	local part
	for part in ${path//;/ }; do
		if [ ! -f "${part}" ]; then
			echo "Missing ${part}" >&2
			exit 1
		fi
	done
}

require_ot_scenario_conf() {
	local scenario="${1}"
	require_conf "${OT_BASE_CONF}"
	require_conf "${SCRIPT_DIR}/nrf52_bsim_${scenario}.conf"
}

build_echo() {
	local overlay="${1}"
	local bsim_conf="${2}"
	local label="${3}"

	cd "${ZEPHYR_BASE}"
	source tests/bsim/compile.source

	echo "Building echo server (${label})..."
	app=samples/net/sockets/echo_server \
		conf_overlay="${overlay}" \
		extra_conf_file="${bsim_conf}" \
		_compile

	echo "Building echo test client (${label})..."
	app=tests/bsim/net/sockets/echo_test \
		conf_overlay="${overlay}" \
		extra_conf_file="${bsim_conf}" \
		_compile
}

run_echo() {
	local overlay="${1}"
	local bsim_conf="${2}"
	local run_script="${3}"
	local label="${4}"

	require_conf "${bsim_conf}"
	require_bsim
	build_echo "${overlay}" "${bsim_conf}" "${label}"
	echo "Running ${label}..."
	"${run_script}"
}

build_ncs_sample() {
	local sample_app="${1}"
	local extra_conf="${2}"
	local sample_name="${sample_app##*/}"
	local build_dir="${ZEPHYR_BASE}/bsim_out/${sample_app}/west_${sample_name}"
	local west_args=(
		-p always -b nrf52_bsim "${NRF_BASE}/${sample_app}"
		-d "${build_dir}" --sysbuild --
		-DEXTRA_CONF_FILE="${extra_conf}"
	)

	if [ -n "${cmake_extra_args:-}" ]; then
		west_args+=(${cmake_extra_args})
	fi

	cd "${NCS_BASE}"
	echo "west build ${west_args[*]}"
	west build "${west_args[@]}"

	local zephyr_exe
	zephyr_exe="$(find "${build_dir}" -path '*/zephyr/zephyr.exe' -print -quit 2>/dev/null || true)"

	if [ -z "${zephyr_exe}" ] || [ ! -f "${zephyr_exe}" ]; then
		echo "Build finished but zephyr.exe not found under ${build_dir}" >&2
		exit 1
	fi
	echo "Built ${sample_app} -> ${zephyr_exe}"
}

build_topology() {
	local bsim_conf
	local overlay

	require_ot_scenario_conf topology
	require_bsim

	bsim_conf="$(ot_conf topology)"
	overlay="overlay-pinger.conf"

	cd "${ZEPHYR_BASE}"
	source tests/bsim/compile.source

	echo "Building topology pinger..."
	app_root="${NRF_BASE}"
	app=tests/bsim/net/topology \
		conf_overlay="${overlay}" \
		extra_conf_file="${bsim_conf}" \
		_compile

	echo "Building topology responder..."
	app_root="${NRF_BASE}"
	app=tests/bsim/net/topology \
		conf_overlay="overlay-responder.conf" \
		extra_conf_file="${bsim_conf}" \
		_compile
}

run_topology() {
	local bsim_conf
	local run_script

	bsim_conf="$(ot_conf topology)"
	run_script="${NRF_BASE}/tests/bsim/net/topology/tests_scripts/topology_ping_ot.sh"

	require_conf "${bsim_conf}"
	require_bsim
	build_topology
	echo "Running net.topology.ping.openthread..."
	chmod +x "${run_script}"
	"${run_script}"
}

build_coap() {
	require_ot_scenario_conf coap
	require_conf "${SCRIPT_DIR}/nrf52_bsim_coap_client.conf"
	require_bsim

	echo "Building OpenThread CoAP server..."
	build_ncs_sample samples/openthread/coap_server "$(ot_conf coap)"

	echo "Building OpenThread CoAP client..."
	build_ncs_sample samples/openthread/coap_client \
		"$(ot_conf coap);${SCRIPT_DIR}/nrf52_bsim_coap_client.conf"
}

build_dataset() {
	require_ot_scenario_conf dataset
	require_bsim

	echo "Building OpenThread CLI (dataset)..."
	build_ncs_sample samples/openthread/cli "$(ot_conf dataset)"
}

list_scenarios() {
	cat <<EOF
scenario          status     ncs_conf
echo-openthread   runnable   ${OT_BASE_CONF}
echo-802154       runnable   ${OT_802154_CONF}
topology          runnable   $(ot_conf topology)
coap              build-only $(ot_conf coap)
dataset           build-only $(ot_conf dataset)
EOF
}

ACTION="${1:-}"
SCENARIO="${2:-}"

case "${ACTION}" in
list)
	list_scenarios
	;;
run)
	case "${SCENARIO}" in
	echo-openthread)
		run_echo "overlay-ot.conf" "${OT_BASE_CONF}" \
			"${ZEPHYR_BASE}/tests/bsim/net/sockets/echo_test/tests_scripts/echo_test_ot.sh" \
			"net.sockets.echo_test.openthread"
		;;
	echo-802154)
		run_echo "overlay-802154.conf" "${OT_802154_CONF}" \
			"${ZEPHYR_BASE}/tests/bsim/net/sockets/echo_test/tests_scripts/echo_test_802154.sh" \
			"net.sockets.echo_test.802154"
		;;
	topology)
		run_topology
		;;
	coap|dataset)
		echo "No Zephyr run script yet for '${SCENARIO}'." >&2
		echo "Use: $0 build ${SCENARIO}" >&2
		exit 1
		;;
	*)
		usage >&2
		exit 1
		;;
	esac
	;;
build)
	case "${SCENARIO}" in
	topology)
		require_bsim
		build_topology
		;;
	coap) build_coap ;;
	dataset) build_dataset ;;
	echo-openthread)
		require_bsim
		build_echo "overlay-ot.conf" "${OT_BASE_CONF}" "echo-openthread"
		;;
	echo-802154)
		require_bsim
		build_echo "overlay-802154.conf" "${OT_802154_CONF}" "echo-802154"
		;;
	*)
		usage >&2
		exit 1
		;;
	esac
	;;
# Backward-compatible aliases for run_echo_test.sh
openthread)
	exec "$0" run echo-openthread
	;;
802154)
	exec "$0" run echo-802154
	;;
*)
	usage >&2
	exit 1
	;;
esac
