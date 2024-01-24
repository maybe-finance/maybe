import { ServerClient as PostmarkServerClient } from 'postmark'
import env from '../../env'

export function initializeEmailClient() {
    switch (env.NX_EMAIL_PROVIDER) {
        case 'postmark':
            if (env.NX_EMAIL_PROVIDER_API_TOKEN) {
                return new PostmarkServerClient(env.NX_EMAIL_PROVIDER_API_TOKEN)
            } else {
                return undefined
            }
        default:
            return undefined
    }
}
