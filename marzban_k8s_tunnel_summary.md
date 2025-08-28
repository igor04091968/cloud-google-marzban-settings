## Marzban Kubernetes Tunnel Setup Summary

**Problem:** The `marzban-controller` application in Kubernetes was only listening on `127.0.0.1`, making it inaccessible from outside the pod, even through a tunnel.

**Solution:**

1.  **Sidecar Proxy:** A `socat` sidecar container was added to the `marzban-controller` pod. This sidecar listens on port `8080` on all interfaces (`0.0.0.0`) and forwards traffic to the Marzban application on `127.0.0.1:8000`.

2.  **Kubernetes Service:** The `marzban-controller` service was modified to target the sidecar's port (`targetPort: 8080`).

3.  **Tunnel:** The `chisel` reverse tunnel connects the external server (`vds1.iri1968.dpdns.org:8443`) to the `NodePort` of the `marzban-controller` service, which then routes traffic to the `socat` sidecar.

This setup successfully exposes the Marzban panel to the public internet through the reverse tunnel.
