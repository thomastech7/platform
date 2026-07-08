# Authentication Configuration

Guide for configuring authentication options, such as disabling local (email/password) login and preventing self-registration to only support OpenID/social providers.

## Configuration Options

To restrict the login page to only support third-party authentication (like OpenID) and disable manual sign-up/password entry, you need to set the following environment variables:

| Variable | Target Service(s) | Description |
| :--- | :--- | :--- |
| `DISABLE_SIGNUP=true` | `front` & `account` | Disables self-registration across the platform (hides the Sign Up tab, disables manual registration endpoints, and disables auto-registration on OAuth/OIDC login). |
| `HIDE_LOCAL_LOGIN=true` | `front` | Hides local username/password and OTP login form inputs, displaying only the configured authentication providers (e.g., OpenID). |

---

## Docker Compose Example

Modify your `docker-compose.yml` file as follows:

```yaml
  account:
    image: thanhnm777/hce-test:account-latest
    environment:
      # ... existing configurations ...
      - DISABLE_SIGNUP=true
    restart: unless-stopped
    networks:
      - huly_net

  front:
    image: thanhnm777/hce-test:front-latest
    environment:
      # ... existing configurations ...
      - DISABLE_SIGNUP=true
      - HIDE_LOCAL_LOGIN=true
    restart: unless-stopped
    networks:
      - huly_net
```

---

## Implementation Details

The variables control behaviors in the following parts of the codebase:

* **Disabling Registration/Sign Up (`DISABLE_SIGNUP=true`)**:
  * **Frontend UI**: [LoginApp.svelte](file:///Users/thanh/work/platform/plugins/login-resources/src/components/LoginApp.svelte#L60-L61) reads `login.metadata.DisableSignUp` to hide the Sign Up tab.
  * **Account Service APIs**: [index.ts](file:///Users/thanh/work/platform/server/account-service/src/index.ts#L137-L138) sets `hasSignUp` to `false` based on the env var, which disables manual `signUp` and `signUpOtp` API endpoints.
  * **OIDC Social Auto-Registration Guard**: In [openid.ts:L107](file:///Users/thanh/work/platform/pods/authProviders/src/openid.ts#L107), `signUpDisabled` is passed into the passport auth callbacks to [utils.ts:L95-L104](file:///Users/thanh/work/platform/pods/authProviders/src/utils.ts#L95-L104), which blocks account creation on first login if the account does not already exist.

* **Hiding Password/Email Login (`HIDE_LOCAL_LOGIN=true`)**:
  * **Frontend UI**: [LoginApp.svelte](file:///Users/thanh/work/platform/plugins/login-resources/src/components/LoginApp.svelte#L60-L61) reads `login.metadata.HideLocalLogin` to hide local input fields and force-renders `ProvidersOnlyForm` (showing only OpenID/social login buttons).
  * **Front Service Config**: Read in the Front service [starter.ts](file:///Users/thanh/work/platform/server/front/src/starter.ts#L114-L117) and forwarded to the frontend client configuration.
