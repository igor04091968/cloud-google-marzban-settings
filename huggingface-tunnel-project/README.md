---
license: mit
title: Advanced Tunnel Container
sdk: docker
emoji: 🚀
colorFrom: gray
colorTo: indigo
pinned: true
app_port: 2222
persistent_storage: true
---

# Advanced Tunnel Container

## Overview

This container provides a multi-purpose tunneling and network testing environment designed to establish a secure and robust connection between a local environment (like Google Cloud Shell) and a remote server (VDS).

It uses a combination of `stunnel` and `SSH` to create a primary tunnel and then establishes multiple reverse tunnels for various services.

See **Help.md** for a detailed description of the architecture, setup, and data flow.