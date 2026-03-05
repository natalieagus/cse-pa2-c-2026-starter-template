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
#   make            # build all
#   make clean      # remove binaries
#   make AP         # build only AP client + server
#   make CP1        # build only CP1 client + server
#   make CP2        # build only CP2 client + server
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

.PHONY: all clean AP CP1 CP2 NoSec

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

clean:
	rm -f $(ALL)
	chmod +x ./setup.sh
	./setup.sh
