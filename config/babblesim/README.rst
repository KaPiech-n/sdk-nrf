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
| test-fw pytest CLI | base + :file:`nrf52_bsim_pytest_cli.conf` | :file:`nrf52_bsim_pytest_cli.overlay` + ``serial-console`` snippet | Runnable |
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
   <ncs>/nrf/config/babblesim/run_bsim_test.sh build pytest-cli

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

test-fw desk PoC (pytest / UART PTY)
************************************

The Thread test framework runs BabbleSim **locally without hardware** via
``test-fw-nrfconnect-thread`` (desk PoC, KRKNWK-22421):

* ``tests/bsim/README.rst`` — env vars, prerequisites, pytest commands
* ``run_bsim_test.sh build pytest-cli`` — OT CLI firmware with serial shell (below)
* ``TestProcedureThread`` + ``BabbleSimHarnessThread`` — same CTF stack as on DK

Requires west ``+babblesim``, this sdk-nrf branch under ``ncs/nrf``, and companion
sdk-nrfxlib changes (``krknwk-22421-ot-cli-bsim``).

Build OT CLI with serial shell for ``THREAD_TEST_BACKEND=bsim`` (same binary for DUT and node):

.. code-block:: console

   <ncs>/nrf/config/babblesim/run_bsim_test.sh build pytest-cli

Then point ``BSIM_ZEPHYR_EXE_DUT`` and ``BSIM_ZEPHYR_EXE_NODE`` at the printed ``zephyr.exe`` path.

PoC limitations
***************

* Thread **1.1 FTD** on BabbleSim for OpenThread tests.
* ``libCryptov1`` warning is expected if BabbleSim crypto was not built.
* Harness / certification tests are not supported on BabbleSim.
* **No simulated MPSL** — 802.15.4 uses open-source SL in single-PHY mode
  (``CONFIG_NRF_802154_SL_OPENSOURCE=y``). Multi-node BabbleSim works; Thread + BLE
  multiprotocol on one device does not. See Confluence BabbleSim PoC summary (Limitations).
