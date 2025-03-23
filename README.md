# Elixir URL Poller

A declarative URL polling system built with Elixir, featuring dynamic worker management and reconciliation of desired state

## Context

In 2024 I followed an introductory course on Elixir. However, I never implemented my own project. In the last couple of weeks I have been thinking about how, in some aspects, the OTP and Kubernetes are similar. The result is this little pet project:

- Built with Elixir and OTP
- Inspired by declarative systems like Kubernetes

## Overview

This project implements a fleet of URL polling workers in Elixir that can be declaratively managed. It uses Elixir's OTP framework with a `DynamicSupervisor`, `GenServer`, and `Registry` to create a system that:
- Spawns worker processes to poll configured URLs
- Reconciles the current state with a desired state
- Dynamically creates, updates, and removes workers at runtime
- Handles configuration updates declaratively

## Features

- **Declarative Configuration**: Define the desired state of URL pollers and the system reconciles automatically
- **Dynamic Management**: Add, remove, or update pollers at runtime
- **Fault Tolerance**: Built with OTP supervision
- **Unique Identification**: Uses Registry for worker tracking

## Prerequisites

- [Nix](https://nixos.org/download.html) with flake support enabled
- Git

## Installation

1. Clone the repository:

2. Enter the Nix development shell:
   ```bash
   nix develop
   ```

3. Install Elixir dependencies:
   ```bash
   mix deps.get
   ```

## Usage

1. Start the application in interactive mode within the Nix shell:
   ```bash
   iex -S mix
   ```

2. The application starts with an empty config.

3. Define and apply a new desired state:
   ```elixir
   desired_state = [
     [id: "worker1", name: "poller-1", urls: ["https://example.com"], interval: 2000],
     [id: "worker2", name: "poller-2", urls: ["https://google.com"], interval: 10000]
   ]
   UrlPoller.WorkerSupervisor.reconcile(desired_state)
   ```

4. Check current workers:
   ```elixir
   UrlPoller.WorkerSupervisor.list_workers_with_info()
   ```

5. Update the desired state (e.g., remove a worker):
   ```elixir
   new_desired_state = [
     [id: "worker1", name: "poller-1-updated", urls: ["https://example.org"], interval: 3000]
   ]
   UrlPoller.WorkerSupervisor.reconcile(new_desired_state)
   ```
6. Clean up all workers
   ```elixir
   UrlPoller.WorkerSupervisor.reconcile([])
   ```

## Development Environment

This project uses a Nix flake to provide a reproducible development environment. The flake defines:
- Elixir 1.17
- Erlang 27
- Node.js 20
- Platform-specific tools:
  - Linux: `gigalixir`, `inotify-tools`, `libnotify`
  - macOS: `terminal-notifier`, CoreFoundation, CoreServices


## Configuration

Each worker configuration is a keyword list with:
- `id`: Unique identifier (string)
- `name`: Worker name (string)
- `urls`: List of URLs to poll (list of strings)
- `interval`: Polling interval in milliseconds (positive integer)

Example:
```elixir
[id: "worker1", name: "poller-1", urls: ["https://example.com"], interval: 5000]
```

## How It Works

1. The `Application` starts with an initial empty state
2. `WorkerSupervisor` uses `DynamicSupervisor` to manage worker processes.
3. `Worker` processes poll URLs at their configured intervals
4. The `Registry` tracks workers by their IDs
5. Reconciliation on-demand to:
   - Create new workers from desired state
   - Update existing workers if configuration differs
   - Remove workers not in desired state


```text
+-------------------+
|   Application     |
+-------------------+
         |
         v
+-------------------+         +-----------------+
| WorkerSupervisor  |<------->|     Registry    |
|(DynamicSupervisor)|         | (Tracks Workers)|
|                   |         +-----------------+
+-------------------+                |
         |                           |
         v                           |
+-------------------+                |
|     Workers       |<---------------+
| (GenServer)       |
| - Poll URLs      |
+-------------------+
```
