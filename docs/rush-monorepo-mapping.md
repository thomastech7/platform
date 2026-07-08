# Rush Monorepo & Service Mappings

This guide explains how Huly utilizes the Microsoft Rush monorepo manager and provides a mapping from the Docker Compose services (`roles/huly/files/docker-compose.yml`) to their respective source code paths in the repository.

---

## 1. Rush Monorepo Architecture

Huly is structured as a monorepo containing multiple packages (TypeScript/Node and Rust) managed by [Microsoft Rush](https://rushjs.io/). 

### Key Config Files
- **`rush.json`**: The root configuration file. It lists all projects in the monorepo, their package names, and their folder paths.
- **`common/config/rush/command-line.json`**: Defines custom Rush commands and phases (such as `docker:build`, which calls the `_phase:docker-build` phase in all packages).
- **`common/scripts/docker.sh`**: A shell script that triggers sequential or parallel Rush docker builds (`rush docker:build`) for all requested services.

### Directory Structure
- **`foundations/`**: Fundamental services and core libraries (some written in Rust, some in TypeScript).
- **`pods/`**: Deployable server runtimes/entrypoints that run as backend services.
- **`services/`**: Independent microservices/plugins that provide additional functionality (such as email, push notifications, billing, search, etc.).
- **`plugins/` & `server-plugins/`**: Frontend and backend plugins that extend the core capabilities of the Huly workspace.

---

## 2. Docker Compose Service to Source Code Mapping

Below is the mapping for every service defined in Huly's Ansible/Docker Compose file (`roles/huly/files/docker-compose.yml`) to its corresponding package in the repository.

### Built-in Custom Huly Services

| Service Name (Compose) | Docker Image | Rush Package Name | Source Code Project Path | Language / Description |
| :--- | :--- | :--- | :--- | :--- |
| **`front`** | `hardcoreeng/front` | `@hcengineering/pod-front` | [pods/front](file:///Users/thanh/work/platform/pods/front) | TypeScript. Serves the web UI & routes static assets. |
| **`transactor`** | `hardcoreeng/transactor` | `@hcengineering/pod-server` | [pods/server](file:///Users/thanh/work/platform/pods/server) | TypeScript. The main transactor/backend server. |
| **`account`** | `hardcoreeng/account` | `@hcengineering/pod-account` | [pods/account](file:///Users/thanh/work/platform/pods/account) | TypeScript. Handles auth, account provisioning, etc. |
| **`workspace`** | `hardcoreeng/workspace` | `@hcengineering/pod-workspace` | [pods/workspace](file:///Users/thanh/work/platform/pods/workspace) | TypeScript. Workspace management and configuration. |
| **`collaborator`** | `hardcoreeng/collaborator` | `@hcengineering/pod-collaborator` | [pods/collaborator](file:///Users/thanh/work/platform/pods/collaborator) | TypeScript. Handles live collaborative sessions. |
| **`fulltext`** | `hardcoreeng/fulltext` | `@hcengineering/pod-fulltext` | [pods/fulltext](file:///Users/thanh/work/platform/pods/fulltext) | TypeScript. Interface layer to Elasticsearch. |
| **`stats`** | `hardcoreeng/stats` | `@hcengineering/pod-stats` | [pods/stats](file:///Users/thanh/work/platform/pods/stats) | TypeScript. Statistics and usage metrics collector. |
| **`notification`** | `hardcoreeng/notification` | `@hcengineering/pod-notification` | [services/notification/pod-notification](file:///Users/thanh/work/platform/services/notification/pod-notification) | TypeScript. Generic VAPID-based push notifications. |
| **`rekoni`** | `hardcoreeng/rekoni-service` | `@hcengineering/rekoni-service` | [services/rekoni](file:///Users/thanh/work/platform/services/rekoni) | TypeScript. Core collaboration document backend. |
| **`love`** | `hardcoreeng/love` | `@hcengineering/pod-love` | [services/love](file:///Users/thanh/work/platform/services/love) | TypeScript. Huly's love feedback service. |
| **`hulypulse`** | `hardcoreeng/hulypulse` | *N/A (Rust Subtree)* | [foundations/hulypulse](file:///Users/thanh/work/platform/foundations/hulypulse) | Rust. WebSocket whiteboard notifier (realtime sync). |
| **`kvs`** | `hardcoreeng/hulykvs` | `@hcengineering/hulylake` | [foundations/hulylake](file:///Users/thanh/work/platform/foundations/hulylake) | Rust. Key-value configuration store (binary name: `hulylake`). |

### Third-Party / Database Services

These services run standard third-party images and do not compile custom monorepo code:

| Service Name (Compose) | Third-Party Image | Description |
| :--- | :--- | :--- |
| **`nginx`** | `nginx:1.21.3` | Reverse proxy and SSL/TLS terminator. |
| **`cockroach`** | `cockroachdb/cockroach:latest-v24.2` | Primary SQL database. |
| **`redpanda`** | `docker.redpanda.com/redpandadata/redpanda:v24.3.6` | Fast Kafka-compatible event queue used for system messages. |
| **`minio`** | `minio/minio` | S3-compatible object storage for file uploads. |
| **`elastic`** | `elasticsearch:7.14.2` | Search index engine (loaded with ingest-attachment plugin). |
