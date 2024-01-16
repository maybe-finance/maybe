import { ServerClient } from 'postmark'
import env from '../../env'

const postmark = env.NX_POSTMARK_API_TOKEN ? new ServerClient(env.NX_POSTMARK_API_TOKEN) : undefined

export default postmark
