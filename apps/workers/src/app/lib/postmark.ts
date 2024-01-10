import { ServerClient } from 'postmark'
import env from '../../env'

const postmark = new ServerClient(env.NX_POSTMARK_API_TOKEN)

export default postmark
