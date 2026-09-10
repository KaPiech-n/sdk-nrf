.. _ncs_babblesim_openthread_test:

BabbleSim tests on NCS (nrf52_bsim)
###################################

NCS-specific Kconfig fragments and helper scripts for Zephyr BabbleSim net tests.

Prerequisites
*************

1. BabbleSim built once: ``cd <ncs>/tools/bsim && make everything -j8``
2. **sdk-nrfxlib** branch ``krknwk-22421-ot-cli-bsim``
3. Zephyr SDK **1.0.1** toolchain in ``PATH``

Configuration layout
********************

All OpenThread BabbleSim scenarios share :file:`nrf52_bsim_openthread.conf`.
Add a small scenario fragment when needed:

.. code-block:: none

   nrf52_bsim_openthread.conf[;nrf52_bsim_<scenario>.conf]

| Scenario | NCS conf chain | Zephyr overlay | Status |
|----------|----------------|----------------|--------|
| Echo (OpenThread) | :file:`nrf52_bsim_openthread.conf` | ``overlay-ot.conf`` | Runnable |
| Echo (802.15.4) | :file:`nrf52_bsim_ieee802154.conf` | ``overlay-802154.conf`` | Runnable |
| Topology / ping | base + :file:`nrf52_bsim_topology.conf` | ``nrf/tests/bsim/net/topology/`` overlays | Runnable |
| CoAP | base + :file:`nrf52_bsim_coap.conf` | TBD in ``tests/bsim/net/coap/`` | Build-only |
| Dataset / channel | base + :file:`nrf52_bsim_dataset.conf` | TBD in ``tests/bsim/net/dataset/`` | Build-only |

Quick run
*********

.. code-block:: console

   export ZEPHYR_BASE=<ncs>/zephyr
   export BSIM_OUT_PATH=<ncs>/tools/bsim

   <ncs>/nrf/config/babblesim/run_bsim_test.sh list
   <ncs>/nrf/config/babblesim/run_bsim_test.sh run echo-openthread
   <ncs>/nrf/config/babblesim/run_bsim_test.sh run echo-802154
   <ncs>/nrf/config/babblesim/run_bsim_test.sh run topology
   <ncs>/nrf/config/babblesim/run_bsim_test.sh build coap
   <ncs>/nrf/config/babblesim/run_bsim_test.sh build dataset

``run_echo_test.sh`` remains as a wrapper (``openthread`` / ``802154`` aliases).

Pass criteria:

* Echo: ``INFO: echo_client PASSED`` (≥ 100 packets in ~20–25 s)
* Topology ping: ``INFO: topology_ping PASSED`` (≥ 5 ICMP replies in ~35 s)

See :ref:`ncs_babblesim_experimental` for comparison with Matter ``native_sim``.

Manual west build (any scenario)
********************************

.. code-block:: console

   west build -p always -b nrf52_bsim nrf/samples/openthread/cli \
     -d build/ot-cli-bsim --sysbuild -- \
     -DEXTRA_CONF_FILE="<ncs>/nrf/config/babblesim/nrf52_bsim_openthread.conf;<ncs>/nrf/config/babblesim/nrf52_bsim_topology.conf"

OpenThread CLI sample board file :file:`samples/openthread/cli/boards/nrf52_bsim.conf`
duplicates the base settings for standalone ``west build`` without ``EXTRA_CONF_FILE``.

test-fw CI integration (Phase 2)
*********************************

The Thread test framework can run BabbleSim smoke on a **build agent** (no hardware)
via ``test-fw-nrfconnect-thread``:

* ``conf/scripts/run_bsim_smoke.sh`` — calls :file:`run_bsim_test.sh` for echo scenarios
* Jenkins param ``TEST_RUN_BSIM_SMOKE`` + ``ThreadTestWithBsim`` stage
* Scenario registry: ``tests/bsim/smoke_suite.yaml``

Requires west ``+babblesim`` and this sdk-nrf branch checked out under ``ncs/nrf``.

PoC limitations
***************

* Thread **1.1 FTD** on BabbleSim for OpenThread tests.
* ``libCryptov1`` warning is expected if BabbleSim crypto was not built.
* Harness / certification tests are not supported on BabbleSim.
