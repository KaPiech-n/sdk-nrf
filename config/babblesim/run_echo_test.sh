#!/usr/bin/env bash
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
# Backward-compatible wrapper. Prefer run_bsim_test.sh.
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/run_bsim_test.sh" "$@"
