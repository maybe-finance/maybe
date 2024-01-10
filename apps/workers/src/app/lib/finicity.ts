import { FinicityApi } from '@maybe-finance/finicity-api'
import env from '../../env'

const finicity = new FinicityApi(
    env.NX_FINICITY_APP_KEY,
    env.NX_FINICITY_PARTNER_ID,
    env.NX_FINICITY_PARTNER_SECRET
)

export default finicity
