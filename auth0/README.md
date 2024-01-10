## Quick Start

### Setting up env locally

```
AUTH0_ENV=development
AUTH0_DEPLOY_CLIENT_SECRET=
POSTMARK_SMTP_PASS=
```

-   `AUTH0_ENV` - This is either `development`, `staging`, or `production`. This should **always** be `development` when working locally.
-   `AUTH0_DEPLOY_CLIENT_SECRET` - The secret for the `auth0-deploy-cli-extension` application in Auth0 dashboard
-   `POSTMARK_SMTP_PASS` - Go to Postmark => Servers => "Mail Server" => Message Streams => "Default Transactional Message Stream" => Settings

You will need to install the Auth0 Client to test templates (you might need to change the commands depending on your platform):

```bash
# Linux example
wget -c https://github.com/auth0/auth0-cli/releases/download/v0.11.2/auth0-cli_0.11.2_Linux_x86_64.tar.gz -O - | sudo tar -xz -C /usr/local/bin/
```

### How deployments work

Per the [Auth0 docs](https://github.com/auth0/auth0-deploy-cli/tree/master/examples/directory), this repository uses Github Actions to define each Auth0 tenant configuration.

Maybe has 3 tenants:

1. `maybe-finance-development`
2. `maybe-finance-staging`
3. `maybe-finance-production`

On each push to a branch with `auth0` in it (e.g. `someuser/pr-title-auth0`), the configuration in `tenant.yaml` will be deployed to the **staging** tenant.

On each push to `main`, the configuration in `tenant.yaml` will be deployed to the **production** tenant.

These rules are defined in `.github/workflows/deploy-auth0-staging.yml` and `.github/workflows/deploy-auth0-prod.yml` respectively.

## Editing and Testing

### `tenant.yaml`

The `tenant.yaml` file will accept any options present in the [Auth0 Management API](https://auth0.com/docs/api/management/v2).

[Here is a sample `tenant.yaml` file](https://github.com/auth0/auth0-deploy-cli/blob/master/examples/yaml/tenant.yaml).

For example, you can define tenant-wide settings using the Management API [tenant endpoint](https://auth0.com/docs/api/management/v2#!/Tenants/tenant_settings_route) (abbreviated):

```json
# Abbreviated Management API V2 tenant endpoint GET response
{
    "flags": {
       "revoke_refresh_token_grant": false,
        ...
    },
    "friendly_name": "My Company",
    "picture_url": "https://mycompany.org/logo.png",
    "support_email": "support@mycompany.org",
    ...
}
```

```yaml
# tenant.yaml

tenant:
    flags:
        revoke_refresh_token_grant: false
    friendly_name: Maybe Finance
    picture_url: https://assets.maybe.co/images/maybe.svg
    support_email: hello@maybe.co
```

### Testing custom templates

Testing custom templates (`/auth0/emailTemplates` and `/auth0/pages`) happens in 3 steps:

1. Run `live-server` with `yarn auth0:edit`. You can make HTML/CSS changes in this view
2. To deploy to the dev tenant, run `yarn auth0:deploy` (make sure your `.env` is setup per instructions at top of this README)
3. To test the new deployment, run `yarn auth0:test`

Unfortunately, you will have to deploy **every time** you make changes to properly test since Auth0 does not have many developer tools.

References:

-   Auth0 client reference - https://github.com/auth0/auth0.js/tree/master/example
-   Auth0 developer tool docs - https://auth0.github.io/auth0-cli/
-   Relevant Auth0 docs - https://auth0.com/docs/brand-and-customize/universal-login-page-templates#using-the-auth0-cli-

### Password Reset

Of special note is the `/auth0/pages/password_reset.html` page. Auth0 currently does not have an API for password resets, but an Auth0 employee created an
[open source example](https://github.com/auth0/auth0-custom-password-reset-hosted-page) of how to tap into the login page endpoints to customize it. If this page ever breaks (due to changes in internal Auth0 API) we can easily revert back to Universal PW reset in `tenant.yaml`:

```yaml
emailTemplates:
    - template: reset_email
      body: ./emailTemplates/reset_email.html
      enabled: false # CHANGE THIS
```

Setting this to false will revert to the default Auth0 password reset widget (not Maybe branded, but fully functional)
