import { FinicityApi } from '@maybe-finance/finicity-api'
import { getWebhookUrl } from './webhook'
import env from '../../env'

const finicity = new FinicityApi(
    env.NX_FINICITY_APP_KEY,
    env.NX_FINICITY_PARTNER_ID,
    env.NX_FINICITY_PARTNER_SECRET
)

export default finicity

export async function getFinicityWebhookUrl() {
    const webhookUrl = await getWebhookUrl()
    return `${webhookUrl}/v1/finicity/webhook`
}

export async function getFinicityTxPushUrl() {
    const webhookUrl = await getWebhookUrl()
    return `${webhookUrl}/v1/finicity/txpush`
}
