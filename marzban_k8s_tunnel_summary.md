## Marzban Kubernetes Tunnel Setup Summary

**Problem:** The `marzban-controller` application in Kubernetes was only listening on `127.0.0.1`, making it inaccessible from outside the pod, even through a tunnel.

**Solution:**

1.  **Sidecar Proxy:** A `socat` sidecar container was added to the `marzban-controller` pod. This sidecar listens on port `8080` on all interfaces (`0.0.0.0`) and forwards traffic to the Marzban application on `127.0.0.1:8000`.

2.  **Kubernetes Service:** The `marzban-controller` service was modified to target the sidecar's port (`targetPort: 8080`).

3.  **Tunnel:** The `chisel` reverse tunnel connects the external server (`vds1.iri1968.dpdns.org:8443`) to the `NodePort` of the `marzban-controller` service, which then routes traffic to the `socat` sidecar.

This setup successfully exposes the Marzban panel to the public internet through the reverse tunnel.

---

## Troubleshooting

### Resetting Admin Password / Users

**Problem:** It is not possible to manage users (create, delete, reset password) using `marzban cli` inside the `gozargah/marzban:latest` container via `kubectl exec`. The container is a minimal image that does not include the `marzban` CLI tool in its `PATH` or easily accessible locations.

**Solution (Full Reset):**

The only reliable method to reset user data is to completely wipe the database and let Marzban re-initialize it.

**Warning:** This will delete ALL users and settings.

1.  **Delete the database file:** The database is a single SQLite file located in the persistent volume. Execute the following command, replacing `<pod-name>` with the name of your `marzban-controller` pod:
    ```bash
    kubectl exec -n marzban <pod-name> -- rm /var/lib/marzban/db.sqlite3
    ```

2.  **Restart the controller pod:** Deleting the pod will cause Kubernetes to automatically recreate it. The new pod will start with a fresh, empty database.
    ```bash
    kubectl delete pod -n marzban -l app=marzban-controller
    ```

3.  **Create a new admin:** After the pod restarts, navigate to the Marzban web UI. You will be prompted to create the first admin user again.