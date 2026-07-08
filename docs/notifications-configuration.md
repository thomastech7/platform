# Push Notifications Configuration

This guide describes how to configure the backend server and transactor for push notifications to ensure they resolve to the correct public URL when clicked on external devices (like mobile phones).

## Problem: Push Notifications Redirect to `localhost:8087`

When deploying Huly in a self-hosted environment, push notifications may successfully arrive on external devices, but clicking them might redirect the user to `http://localhost:8087` instead of the actual server URL.

### Why this happens
1. The **`transactor` service** handles the application logic and is responsible for generating the specific redirection URL payload (containing the workspace and document IDs) when a push notification trigger fires.
2. In the source code (`server-plugins/notification-resources/src/push.ts`), the URL prefix is determined by `FRONT_URL` mapped to the transactor:
   ```typescript
   const front = control.branding?.front ?? getMetadata(serverCore.metadata.FrontUrl) ?? ''
   ...
   data.url = concatLink(front, path.join('/'))
   ```
3. If the transactor's environment is configured with `FRONT_URL=http://localhost:8087`, the URL payload inside the push notification becomes `http://localhost:8087/workbench/...`.
4. The **`notification` service** is a lightweight, generic microservice that merely forwards this payload to the push providers. It has no knowledge of Huly's routes or base URL and cannot modify the domain.

### Why it might work on a local MacBook but fail on phones
Huly's service worker (`plugins/notification/src/serviceWorker.ts`) tries to match the incoming notification's pathname with currently open browser tabs. 

* **If a matching tab is open (e.g. on MacBook)**: The service worker ignores the hostname mismatch, focuses the existing open tab, and navigates internally.
* **If no matching tab is open (e.g. on a phone)**: The service worker falls back to opening a brand-new window using `clients.openWindow(notificationUrl)`. Since the phone's loopback interface has nothing running on `localhost:8087`, the page fails to load.

---

## Resolution

To ensure push notifications resolve correctly on all devices, configure the **`FRONT_URL`** environment variable under the **`transactor`** service in your `docker-compose.yml` to point to the public host address:

```yaml
  transactor:
    image: thanhnm777/hce-test:transactor-latest
    environment:
      - SERVER_PORT=3333
      - SERVER_SECRET=${SECRET}
      - DB_URL=${CR_DB_URL}
      - STORAGE_CONFIG=minio|minio?accessKey=minioadmin&secretKey=minioadmin
      - FRONT_URL=http${SECURE:+s}://${HOST_ADDRESS}
      - ACCOUNTS_URL=http://account:3000
      - WEB_PUSH_URL=http://notification:8091
```
