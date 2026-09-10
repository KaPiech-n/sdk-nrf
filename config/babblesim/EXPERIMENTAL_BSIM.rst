.. _ncs_babblesim_experimental:

Experimental BabbleSim lane (Thread)
####################################

**Status:** PoC for KRKNWK-22421 — compare with Matter ``native_sim`` (see
`ncs-matter PR #56 <https://github.com/nrfconnect/ncs-matter/pull/56>`_).

Matter NativeSim vs Thread BabbleSim
************************************

.. list-table::
   :header-rows: 1

   * - Aspect
     - Matter ``native_sim`` (ncs-matter)
     - Thread ``nrf52_bsim`` (this PoC)
   * - Target
     - ``native_sim`` (host POSIX)
     - ``nrf52_bsim`` (BabbleSim + nRF HW models)
   * - Radio / MAC
     - Not exercised (cluster logic, persistence, OTA state)
     - Simulated 802.15.4 + OpenThread stack
   * - Multi-node
     - Sample-specific (e.g. light bulb + controller)
     - BabbleSim PHY connects simulated devices
   * - Shell / CLI
     - UART console on native_sim builds
     - Not in PoC (in-firmware pass criteria via ``bstest``)
   * - CI entry
     - Sample build + native_sim run scripts
     - ``run_bsim_test.sh`` / test-fw ``run_bsim_smoke.sh``

Use BabbleSim for
*****************

* OpenThread attach and IPv6 connectivity on simulated nRF52
* Multi-node scenarios without hardware (echo, topology ping)
* Regression before DK-based test-fw lanes

Validate on hardware (or full DK test-fw) for
*********************************************

* Serial ``ot`` CLI flows (commissioning, dataset management scripts)
* Sniffer-based checks, FEM, multiprotocol, Harness/certification
* Anything requiring real radio timing / coexistence

Runnable scenarios today
************************

* ``echo-openthread`` / ``echo-802154`` — Zephyr socket echo (stack smoke)
* ``topology`` — 2-node Thread ICMP ping (subset of ``test_form_topology_and_ping_cli``)

Build-only (next steps)
***********************

* ``coap``, ``dataset`` — Kconfig + sample builds; Zephyr run scripts TBD
