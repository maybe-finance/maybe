import type { SharedType } from '@maybe-finance/shared'
import { ManagementClient } from 'auth0'
import env from '../../env'

/**
 * Management API Documentation
 *   - https://auth0.com/docs/api/management/v2
 *   - https://auth0.github.io/node-auth0/module-management.ManagementClient.html
 */
export const managementClient = new ManagementClient<
    SharedType.MaybeAppMetadata,
    SharedType.MaybeUserMetadata
>({
    domain: env.NX_AUTH0_DOMAIN,
    clientId: env.NX_AUTH0_MGMT_CLIENT_ID,
    clientSecret: env.NX_AUTH0_MGMT_CLIENT_SECRET,
    scope: 'read:users update:users delete:users',
})
