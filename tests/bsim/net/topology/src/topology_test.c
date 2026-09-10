/*
 * Copyright (c) 2026 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "bs_types.h"
#include "bs_tracing.h"
#include "bs_utils.h"
#include "time_machine.h"
#include "bstests.h"

#define WAIT_TIME 35 /* seconds; OT attach on BabbleSim */

extern volatile int topology_ping_reply_count;
extern enum bst_result_t bst_result;

#define FAIL(...)					\
	do {						\
		bst_result = Failed;			\
		bs_trace_error_time_line(__VA_ARGS__);	\
	} while (0)

#define PASS(...)					\
	do {						\
		bst_result = Passed;			\
		bs_trace_info_time(1, __VA_ARGS__);	\
	} while (0)

static void test_topology_ping_init(void)
{
	bst_ticker_set_next_tick_absolute(WAIT_TIME * 1e6);
	bst_result = In_progress;
}

static void test_topology_ping_tick(bs_time_t HW_device_time)
{
	int replies = topology_ping_reply_count;

	bs_trace_info_time(2, "%i ICMP replies received, expected >= %i\n",
			   replies, CONFIG_TOPOLOGY_BSIM_PASS_THRESHOLD);

	if (replies >= CONFIG_TOPOLOGY_BSIM_PASS_THRESHOLD) {
		PASS("topology_ping PASSED\n");
		bs_trace_exit("Done, disconnecting from simulation\n");
	} else {
		FAIL("topology_ping FAILED (only %i replies after %i seconds)\n",
		     replies, WAIT_TIME);
	}
}

static const struct bst_test_instance test_topology_ping[] = {
	{
		.test_id = "topology_ping",
		.test_descr = "Two-node OpenThread BabbleSim topology ping. "
			      "Pinger waits for Thread attach, sends ICMP echo requests to "
			      "a peer on the same network, and checks reply count.",
		.test_pre_init_f = test_topology_ping_init,
		.test_tick_f = test_topology_ping_tick,
	},
	BSTEST_END_MARKER
};

struct bst_test_list *test_topology_ping_install(struct bst_test_list *tests)
{
	tests = bst_add_tests(tests, test_topology_ping);
	return tests;
}
