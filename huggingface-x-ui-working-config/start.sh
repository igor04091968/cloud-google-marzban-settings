#!/bin/bash
# The Dockerfile already installed x-ui to /opt/x-ui.
# This script just needs to run it from the correct working directory.
cd /opt/x-ui/x-ui
./x-ui
