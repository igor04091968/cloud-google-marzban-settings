# x-ui Container with Synchronization

This container runs the x-ui panel and includes a feature to automatically synchronize the `x-ui.db` and `config.json` files to a Git repository.

## Features

- **x-ui panel:** The latest version of the 3x-ui panel.
- **Chisel tunnel:** Exposes the x-ui panel to the internet through a reverse tunnel.
- **Synchronization:** Automatically synchronizes the `x-ui.db` and `config.json` files to a Git repository every 12 hours.

## How to Build and Run

1.  **Build the image:**

    ```bash
    docker build -t local-x-ui .
    ```

2.  **Run the container:**

    ```bash
    docker run -d --name local-x-ui-container -v "/path/to/your/git/repo":"/git" -v "/path/to/your/x-ui-config":"/etc/x-ui" -v "/path/to/your/.ssh":"/root/.ssh" local-x-ui
    ```

    **Note:**

    - Replace `/path/to/your/git/repo` with the absolute path to your Git repository.
    - Replace `/path/to/your/x-ui-config` with the absolute path to your x-ui config directory.
    - Replace `/path/to/your/.ssh` with the absolute path to your .ssh directory.