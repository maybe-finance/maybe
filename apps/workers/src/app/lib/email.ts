import { ServerClient as PostmarkServerClient } from 'postmark'
import env from '../../env'

export function initializeEmailClient() {
    switch (process.env.NX_EMAIL_PROVIDER) {
        case 'postmark':
            if (env.NX_EMAIL_PROVIDER_API_TOKEN) {
                return new PostmarkServerClient(env.NX_EMAIL_PROVIDER_API_TOKEN)
            } else {
                throw new Error('Missing Postmark API token')
            }
        default:
            throw new Error('Invalid email provider')
    }
}
