# 50.005 Programming Assignment 2 (C / OpenSSL)

This assignment requires knowledge from Network Security and basic knowledge in C.

## Secure FTP != HTTPS

Note that you will be implementing Secure FTP as your own whole new application layer protocol. In NO WAY we are relying on HTTP/s. Please do not confuse the materials, you don't need to know materials in Week 11 and 12 before getting started.

## Running the code

### Install required libraries

This assignment requires `gcc` (or `clang`) and the OpenSSL development headers.

```bash
# Ubuntu / Debian
sudo apt-get install build-essential libssl-dev

# macOS (Homebrew) — the Makefile auto-detects the path
brew install openssl

# Fedora / RHEL
sudo dnf install gcc openssl-devel
```

### Run `./setup.sh`

Run this in the root project directory:

```
chmod +x ./setup.sh
./setup.sh
```

This will create 3 directories: `/recv_files`, `/recv_files_enc`, and `/send_files_enc` in the project root. They are all empty directories that can't be added in `.git`.

### Build

```
make
```

This compiles all source files. The Makefile automatically detects macOS vs Linux and finds the OpenSSL headers.

### Run server and client files

In two separate shell sessions, run (assuming you're in root project directory):

```
./ServerWithoutSecurity
```

and:

```
./ClientWithoutSecurity
```

### Using different machines

You can also host the Server file in another computer:

```sh
./ServerWithoutSecurity [PORT] 0.0.0.0
```

The client computer can connect to it using the command:

```sh
./ClientWithoutSecurity [PORT] [SERVER-IP-ADDRESS]
```
