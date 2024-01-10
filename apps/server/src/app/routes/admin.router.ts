import { Router } from 'express'
import { auth, claimCheck } from 'express-openid-connect'
import { createBullBoard } from '@bull-board/api'
import { BullAdapter } from '@bull-board/api/bullAdapter'
import { ExpressAdapter } from '@bull-board/express'
import { AuthUtil, BullQueue } from '@maybe-finance/server/shared'
import { SharedType } from '@maybe-finance/shared'
import { queueService } from '../lib/endpoint'
import env from '../../env'

const router = Router()

const serverAdapter = new ExpressAdapter().setBasePath('/admin/bullmq')

createBullBoard({
    queues: queueService.allQueues
        .filter((q): q is BullQueue => q instanceof BullQueue)
        .map((q) => new BullAdapter(q.queue)),
    serverAdapter,
})

const isProd = process.env.NODE_ENV === 'production' && process.env.IS_PULL_REQUEST !== 'true'

const prodCookieConfig = isProd
    ? {
          session: {
              cookie: {
                  domain: '.maybe.co',
                  path: '/admin',
              },
          },
      }
    : {}

// This will ensure that only Auth0 users with the "admin" role can visit these pages
router.use(
    auth({
        authRequired: true,
        idpLogout: true, // Logout of Auth0 provider
        auth0Logout: isProd, // Same as idpLogout, but for custom domain
        secret: env.NX_SESSION_SECRET,
        baseURL: `${env.NX_API_URL}/admin`,
        clientID: env.NX_AUTH0_CLIENT_ID,
        clientSecret: env.NX_AUTH0_CLIENT_SECRET,
        issuerBaseURL: `https://${env.NX_AUTH0_CUSTOM_DOMAIN}`,
        authorizationParams: {
            response_type: 'code',
            audience: env.NX_AUTH0_AUDIENCE,
            scope: 'openid profile email',
        },
        routes: {
            postLogoutRedirect: env.NX_API_URL,
        },
        ...prodCookieConfig,
    })
)

/**
 * Auth0 requires all custom claims to be namespaced
 * @see https://auth0.com/docs/security/tokens/json-web-tokens/create-namespaced-custom-claims
 *
 * This is the namespace that has been set in the "Rules" section of Maybe's Auth0 dashboard
 *
 * The rule used below is called "Add Roles to ID token", and will attach an array of roles
 * that are assigned to an Auth0 user under the https://maybe.co/roles namespace
 *
 * @see https://auth0.com/docs/authorization/authorization-policies/sample-use-cases-rules-with-authorization#add-user-roles-to-tokens
 */

const adminClaimCheck = claimCheck((_req, claims) => AuthUtil.verifyRoleClaims(claims, 'Admin'))

router.get('/', adminClaimCheck, (req, res) => {
    res.render('pages/dashboard', {
        user: req.oidc.user?.name,
        role: req.oidc.idTokenClaims?.[SharedType.Auth0CustomNamespace.Roles],
    })
})

// Visit /admin/bullmq to see BullMQ Dashboard
router.use('/bullmq', adminClaimCheck, serverAdapter.getRouter())

export default router
