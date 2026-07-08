# Logo & Branding Customization

Guide for customizing the application logos, platform titles, and branding options in Huly.

---

## 1. Login & Onboarding Logos

The logo rendered on the login/sign-up screen and onboarding pages is hardcoded as SVG components. To use your own custom logo, replace the SVG content within the following files:

* **Login Page Logo**: [LoginIcon.svelte](file:///Users/thanh/work/platform/plugins/login-resources/src/components/icons/LoginIcon.svelte)
* **Onboarding Page Logo**: [OnboardIcon.svelte](file:///Users/thanh/work/platform/plugins/onboard-resources/src/components/icons/OnboardIcon.svelte)

### Customizing the Platform Title
The text next to the logo (which defaults to `"Platform"`) can be customized dynamically using the `BRANDING_PATH` JSON file:
1. Provide a branding JSON file mapping your hostname to a branding definition.
2. Set the `title` property to your preferred platform name.
3. Supply this JSON file to your services by defining the `BRANDING_PATH` environment variable.

---

## 2. Workspace Sidebar Logo

The logo at the top of the sidebar (which opens the workspace switcher menu) is handled dynamically in [Logo.svelte](file:///Users/thanh/work/platform/plugins/workbench-resources/src/components/Logo.svelte).

* **How to change it**: 
  1. Open the Huly application in your browser.
  2. Navigate to **Workspace Settings**.
  3. Upload your custom logo under the workspace icon/setting.
  4. If no custom icon is uploaded, the app will fall back to displaying the first letter of the workspace name (e.g. `[T]` for "Thanh") with a red background.
