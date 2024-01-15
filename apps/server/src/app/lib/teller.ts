import { TellerApi } from '@maybe-finance/teller-api'
import { getWebhookUrl } from './webhook'

const teller = new TellerApi()

export default teller

export async function getTellerWebhookUrl() {
    const webhookUrl = await getWebhookUrl()
    return `${webhookUrl}/v1/teller/webhook`
}
