#!/bin/bash
echo "--- Checking connection to vds1.iri1968.dpdns.org ---"
curl -v --connect-timeout 10 vds1.iri1968.dpdns.org:80
echo "--- Connection check finished. Starting x-ui... ---"

# The Dockerfile already installed x-ui to /opt/x-ui.
# This script just needs to run it from the correct working directory.
cd /opt/x-ui/x-ui
./x-ui