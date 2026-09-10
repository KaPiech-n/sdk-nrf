/*
 * Copyright (c) 2026 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * BabbleSim OpenThread topology smoke test.
 * Experimental PoC for KRKNWK-22421 (compare with Matter native_sim lane).
 */

#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/net/net_if.h>
#include <zephyr/net/net_ip.h>
#include <zephyr/net/icmp.h>
#include <zephyr/net/net_config.h>
#include <zephyr/random/random.h>

#include "net_sample_common.h"

LOG_MODULE_REGISTER(topology_bsim, LOG_LEVEL_INF);

#if defined(CONFIG_TOPOLOGY_BSIM_ROLE_PINGER)
volatile int topology_ping_reply_count;
#endif

#if defined(CONFIG_TOPOLOGY_BSIM_ROLE_PINGER)

static struct net_icmp_ctx icmp_ctx;
static struct k_work_delayable ping_work;
static struct net_sockaddr_in6 peer_addr;
static uint16_t ping_id;
static uint16_t ping_seq;

static enum net_verdict icmp_reply_handler(struct net_icmp_ctx *ctx, struct net_pkt *pkt,
					   struct net_icmp_ip_hdr *ip_hdr,
					   struct net_icmp_hdr *icmp_hdr, void *user_data)
{
	ARG_UNUSED(ctx);
	ARG_UNUSED(pkt);
	ARG_UNUSED(ip_hdr);
	ARG_UNUSED(user_data);

	if (icmp_hdr->type == NET_ICMPV6_ECHO_REPLY) {
		topology_ping_reply_count++;
		LOG_INF("ICMP echo reply #%d", topology_ping_reply_count);
	}

	return NET_OK;
}

static void ping_send(struct k_work *work)
{
	struct net_icmp_ping_params params = {
		.identifier = ping_id,
		.sequence = ping_seq++,
		.data = NULL,
		.data_size = 0,
	};

	if (net_icmp_send_echo_request(&icmp_ctx, NULL, (struct net_sockaddr *)&peer_addr,
					 &params, NULL) < 0) {
		LOG_WRN("ICMP echo request failed");
	}

	k_work_schedule(&ping_work, K_MSEC(CONFIG_TOPOLOGY_BSIM_PING_INTERVAL_MS));
}

static int ping_init(void)
{
	int ret;

	ping_id = (uint16_t)sys_rand32_get();

	ret = net_icmp_init_ctx(&icmp_ctx, NET_AF_INET6, NET_ICMPV6_ECHO_REPLY, 0,
				icmp_reply_handler);
	if (ret < 0) {
		LOG_ERR("net_icmp_init_ctx failed (%d)", ret);
		return ret;
	}

	peer_addr.sin6_family = AF_INET6;
	peer_addr.sin6_port = 0;
	ret = net_addr_pton(AF_INET6, CONFIG_NET_CONFIG_PEER_IPV6_ADDR,
			    &peer_addr.sin6_addr);
	if (ret < 0) {
		LOG_ERR("Invalid peer address");
		return ret;
	}

	k_work_init_delayable(&ping_work, ping_send);
	k_work_schedule(&ping_work, K_SECONDS(5));

	return 0;
}

#endif /* CONFIG_TOPOLOGY_BSIM_ROLE_PINGER */

int main(void)
{
	struct net_if *iface;
	int ret;

	LOG_INF("topology BabbleSim node (%s)",
		IS_ENABLED(CONFIG_TOPOLOGY_BSIM_ROLE_PINGER) ? "pinger" : "responder");

	ret = net_config_init_app(NULL, "topology BabbleSim");
	if (ret < 0) {
		LOG_ERR("net_config_init_app failed (%d)", ret);
		return ret;
	}

	wait_for_network();

	iface = net_if_get_default();
	if (iface != NULL) {
		net_if_up(iface);
	}

#if defined(CONFIG_TOPOLOGY_BSIM_ROLE_PINGER)
	ret = ping_init();
	if (ret < 0) {
		return ret;
	}
#endif

	while (true) {
		k_sleep(K_FOREVER);
	}

	return 0;
}
