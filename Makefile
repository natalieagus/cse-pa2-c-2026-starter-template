# =============================================================================
# Makefile for Secure FTP (C / OpenSSL)
# =============================================================================
# Builds all client/server variants.
#
# Requirements: gcc (or clang), OpenSSL development headers
#   - macOS:   brew install openssl   (auto-detected below)
#   - Ubuntu:  sudo apt-get install libssl-dev
#   - Fedora:  sudo dnf install openssl-devel
#
# Usage:
#   make                Build all
#   make NoSec          Build only ClientWithoutSecurity + ServerWithoutSecurity
#   make AP             Build only AP client + server
#   make CP1            Build only CP1 client + server
#   make CP2            Build only CP2 client + server
#   make clean          Remove binaries and reset recv_/send_ directories
#
#   make unit           Compile and run C unit tests under tests/unit/
#   make integration    Run bash integration tests under tests/integration/
#   make test           Run unit then integration
# =============================================================================

CC      = gcc
SRCDIR  = source
COMMON  = $(SRCDIR)/common.c

# ---------- OpenSSL detection (macOS Homebrew vs Linux) ----------
# On macOS, Homebrew installs OpenSSL under a non-standard prefix.
# We auto-detect it so students don't have to set environment variables.
UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
    # macOS — use Homebrew OpenSSL
    OPENSSL_PREFIX := $(shell brew --prefix openssl 2>/dev/null)
    ifeq ($(OPENSSL_PREFIX),)
        $(error OpenSSL not found. Run: brew install openssl)
    endif
    CFLAGS  = -Wall -Wextra -O2 -I $(SRCDIR) -I $(OPENSSL_PREFIX)/include
    LDFLAGS = -L $(OPENSSL_PREFIX)/lib -lssl -lcrypto
else
    # Linux — system OpenSSL (headers in /usr/include/openssl)
    CFLAGS  = -Wall -Wextra -O2 -I $(SRCDIR)
    LDFLAGS = -lssl -lcrypto
endif

# All targets
ALL = ClientWithoutSecurity ServerWithoutSecurity \
      ClientWithSecurityAP ServerWithSecurityAP \
      ClientWithSecurityCP1 ServerWithSecurityCP1 \
      ClientWithSecurityCP2 ServerWithSecurityCP2

.PHONY: all clean AP CP1 CP2 NoSec unit integration test ai-unit-tests

all: $(ALL)

NoSec: ClientWithoutSecurity ServerWithoutSecurity
AP:    ClientWithSecurityAP ServerWithSecurityAP
CP1:   ClientWithSecurityCP1 ServerWithSecurityCP1
CP2:   ClientWithSecurityCP2 ServerWithSecurityCP2

ClientWithoutSecurity: $(SRCDIR)/ClientWithoutSecurity.c $(COMMON)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

ServerWithoutSecurity: $(SRCDIR)/ServerWithoutSecurity.c $(COMMON)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

ClientWithSecurityAP: $(SRCDIR)/ClientWithSecurityAP.c $(COMMON)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

ServerWithSecurityAP: $(SRCDIR)/ServerWithSecurityAP.c $(COMMON)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

ClientWithSecurityCP1: $(SRCDIR)/ClientWithSecurityCP1.c $(COMMON)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

ServerWithSecurityCP1: $(SRCDIR)/ServerWithSecurityCP1.c $(COMMON)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

ClientWithSecurityCP2: $(SRCDIR)/ClientWithSecurityCP2.c $(COMMON)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

ServerWithSecurityCP2: $(SRCDIR)/ServerWithSecurityCP2.c $(COMMON)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# ----------------------------------------------------------------------
# Test infrastructure (added for PA2 testing, same shape as PA1)
# ----------------------------------------------------------------------
TESTS_DIR       = ./tests
UNIT_DIR        = $(TESTS_DIR)/unit
INTEGRATION_DIR = $(TESTS_DIR)/integration
UNITY_DIR       = $(TESTS_DIR)/unity
UNIT_BIN_DIR    = $(UNIT_DIR)/bin

# Auto-discover every tests/unit/test_*.c file.
UNIT_SOURCES = $(wildcard $(UNIT_DIR)/test_*.c)
UNIT_BINS    = $(UNIT_SOURCES:$(UNIT_DIR)/%.c=$(UNIT_BIN_DIR)/%)

# -I $(SRCDIR) so tests can #include "common.h".
# -I $(UNITY_DIR) so tests can #include "unity.h".
# Inherit CFLAGS (which already has -I $(SRCDIR) plus OpenSSL paths on mac).
TEST_CFLAGS = $(CFLAGS) -I $(UNITY_DIR)

# All unit tests link against tests/unity/unity.c and source/common.c.
# In addition, if a paired source file source/<name>.c exists, it is linked
# in too. This supports both:
#   - Tests of helpers already in common.c   (e.g., test_int_bytes.c)
#     -> falls to the second pattern rule, links common.c + unity
#   - Tests of student-written helpers       (e.g., test_authhelpers.c
#     paired with source/authhelpers.c)
#     -> matches the first pattern rule, links the new module + common.c + unity
#
# $(sort) removes duplicates from the prerequisite list. This matters if a
# test happens to be named after a file that already exists in source/
# (notably test_common.c, where the matching source/common.c equals
# $(COMMON)). Without $(sort) the linker would see common.c twice and
# complain about duplicate symbols.

# Rule 1: there is a matching source/<name>.c for this test.
$(UNIT_BIN_DIR)/test_%: $(UNIT_DIR)/test_%.c $(UNITY_DIR)/unity.c $(SRCDIR)/%.c $(COMMON)
	@mkdir -p $(UNIT_BIN_DIR)
	$(CC) $(TEST_CFLAGS) $(sort $^) -o $@ $(LDFLAGS)

# Rule 2: fallback for tests of helpers already in common.c.
$(UNIT_BIN_DIR)/test_%: $(UNIT_DIR)/test_%.c $(UNITY_DIR)/unity.c $(COMMON)
	@mkdir -p $(UNIT_BIN_DIR)
	$(CC) $(TEST_CFLAGS) $^ -o $@ $(LDFLAGS)

# Run every compiled unit test in tests/unit/bin/.
unit: $(UNIT_BINS)
	@echo "==> Running unit tests"
	@pass=0; fail=0; \
	for t in $(UNIT_BINS); do \
	  echo "--- $$t ---"; \
	  if $$t; then pass=$$((pass+1)); else fail=$$((fail+1)); fi; \
	done; \
	echo ""; \
	echo "Unit tests: $$pass passed, $$fail failed"; \
	test $$fail -eq 0

# Run every shell script under tests/integration/test_*.sh.
# Requires ClientWithoutSecurity and ServerWithoutSecurity to be built.
# Note: integration tests are run serially because they all bind to the
# same port (PA2_TEST_PORT, default 14321) and write to recv_files/.
integration: NoSec
	@echo "==> Running integration tests"
	@pass=0; fail=0; \
	for s in $(INTEGRATION_DIR)/test_*.sh; do \
	  [ -f "$$s" ] || continue; \
	  echo "--- $$s ---"; \
	  if bash $$s; then pass=$$((pass+1)); else fail=$$((fail+1)); fi; \
	done; \
	echo ""; \
	echo "Integration tests: $$pass passed, $$fail failed"; \
	test $$fail -eq 0

# Run both unit and integration tests.
test: unit integration

# Invoke the AI-assisted unit test generator for one module.
# Usage:
#   make ai-unit-tests MODULE=common         # tests for the bundled helpers
#   make ai-unit-tests MODULE=authhelpers    # tests for a helper you extracted
#
# The script looks for source/<MODULE>.h and source/<MODULE>.c, builds a
# prompt that includes prompts/generate-unit-tests.md, AGENTS.md, and the
# module's header + source, and either pipes that to your configured AI
# agent (via PA2_AGENT_CMD) or prints it to stdout for you to paste into a
# chat UI manually. See scripts/gen_unit_tests.sh for details.
ai-unit-tests:
	@if [ -z "$(MODULE)" ]; then \
	  echo "Usage: make ai-unit-tests MODULE=name"; \
	  echo "  Looks for source/name.h and source/name.c"; \
	  echo "  Generates tests/unit/test_name.c"; \
	  exit 1; \
	fi
	@bash ./scripts/gen_unit_tests.sh $(MODULE)

# ----------------------------------------------------------------------
# Clean (extended to also remove unit-test binaries)
# ----------------------------------------------------------------------
clean:
	rm -f $(ALL)
	rm -rf $(UNIT_BIN_DIR)
	chmod +x ./setup.sh
	./setup.sh
