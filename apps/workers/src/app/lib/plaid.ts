import { Configuration, PlaidApi, PlaidEnvironments } from 'plaid'
import env from '../../env'

// https://plaid.com/docs/api/versioning/#how-to-set-your-api-version
const configuration = new Configuration({
    basePath: PlaidEnvironments[env.NX_PLAID_ENV],
    baseOptions: {
        headers: {
            'PLAID-CLIENT-ID': env.NX_PLAID_CLIENT_ID,
            'PLAID-SECRET': env.NX_PLAID_SECRET,
        },
    },
})

const plaid = new PlaidApi(configuration)

export default plaid
