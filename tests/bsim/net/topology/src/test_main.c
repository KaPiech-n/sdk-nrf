/*
 * Copyright (c) 2026 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "bstests.h"

#if defined(CONFIG_TOPOLOGY_BSIM_ROLE_PINGER)
extern struct bst_test_list *test_topology_ping_install(struct bst_test_list *tests);
#endif

bst_test_install_t test_installers[] = {
#if defined(CONFIG_TOPOLOGY_BSIM_ROLE_PINGER)
	test_topology_ping_install,
#endif
	NULL
};
