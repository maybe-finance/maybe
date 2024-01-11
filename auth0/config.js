require('dotenv').config()
const path = require('path')
const cli = require('auth0-deploy-cli')
const env = require('./env')

// CI is always set to true in Github Actions environment
if (process.env.ENV === 'production' && !process.env.CI) {
    throw new Error('Cannot deploy to production outside of CI/CD workflow!')
}

let AUTH0_DOMAIN
let AUTH0_CUSTOM_DOMAIN
let AUTH0_CLIENT_ID
let CLIENT_BASE_URLS
let SERVER_BASE_URLS
let ADMIN_ROLE_ID
let BETA_TESTER_ROLE_ID

const trustedOrigins = ['https://*.maybe.co', 'https://*.vercel.app']
const logoutOrigins = [...trustedOrigins]

switch (env.AUTH0_ENV) {
    case 'development':
        AUTH0_DOMAIN = 'REPLACE_THIS'
        AUTH0_CUSTOM_DOMAIN = AUTH0_DOMAIN
        AUTH0_CLIENT_ID = 'REPLACE_THIS'
        // 8484 is for the local auth0-client testing
        CLIENT_BASE_URLS = [
            'http://localhost:4200',
            'http://localhost:8484',
            'https://localhost.maybe.co',
        ]
        CLIENT_LOGOUT_URLS = [...logoutOrigins, 'http://localhost:4200']
        SERVER_BASE_URLS = ['http://localhost:3333']
        ADMIN_ROLE_ID = 'REPLACE_THIS'
        BETA_TESTER_ROLE_ID = 'REPLACE_THIS'
        break
    case 'staging':
        AUTH0_DOMAIN = 'REPLACE_THIS'
        AUTH0_CUSTOM_DOMAIN = AUTH0_DOMAIN
        AUTH0_CLIENT_ID = 'REPLACE_THIS'
        CLIENT_BASE_URLS = ['https://staging-app.maybe.co', ...trustedOrigins]
        CLIENT_LOGOUT_URLS = logoutOrigins
        SERVER_BASE_URLS = ['https://staging-api.maybe.co']
        ADMIN_ROLE_ID = 'REPLACE_THIS'
        BETA_TESTER_ROLE_ID = 'REPLACE_THIS'
        break
    case 'production':
        AUTH0_DOMAIN = 'REPLACE_THIS'
        AUTH0_CUSTOM_DOMAIN = 'login.maybe.co'
        AUTH0_CLIENT_ID = 'REPLACE_THIS'
        CLIENT_BASE_URLS = ['https://app.maybe.co', ...trustedOrigins]
        CLIENT_LOGOUT_URLS = logoutOrigins
        SERVER_BASE_URLS = ['https://api.maybe.co']
        ADMIN_ROLE_ID = 'REPLACE_THIS'
        BETA_TESTER_ROLE_ID = 'REPLACE_THIS'
        break
    default:
        throw new Error("Invalid environment: should be 'development' | 'staging' | 'production'")
}

// https://auth0.com/docs/deploy/deploy-cli-tool/import-export-tenant-configuration-to-yaml-file#example-configuration-file
module.exports = {
    config: {
        AUTH0_DOMAIN: AUTH0_CUSTOM_DOMAIN,
        AUTH0_CLIENT_ID,
        AUTH0_CLIENT_SECRET: env.AUTH0_DEPLOY_CLIENT_SECRET,

        /* If something exists in the tenant, but NOT the tenant.yaml file, the resource in the
       tenant will NOT be deleted (hence, `false`) - keeping this set to false as a safeguard */
        AUTH0_ALLOW_DELETE: false,

        // https://auth0.com/docs/deploy/deploy-cli-tool/environment-variables-and-keyword-mappings
        AUTH0_KEYWORD_REPLACE_MAPPINGS: {
            // While the JWT is issued from login.maybe.co in production, the management API still must use the default auth0.com domain
            AUTH0_DOMAIN,
            CLIENT_BASE_URLS,
            CLIENT_LOGOUT_URLS,
            SERVER_BASE_URLS,
            SERVER_CALLBACK_URLS: SERVER_BASE_URLS.map((url) => `${url}/admin/callback`),
            POSTMARK_SMTP_PASS: env.POSTMARK_SMTP_PASS,
            ADMIN_ROLE_ID: ADMIN_ROLE_ID,
            BETA_TESTER_ROLE_ID: BETA_TESTER_ROLE_ID,
            APPLE_SIGN_IN_SECRET_KEY: env.APPLE_SIGN_IN_SECRET_KEY,
        },
    },
    input_file: path.join(__dirname, 'tenant.yaml'),
    sync: cli.export,
    deploy: cli.deploy,
}
