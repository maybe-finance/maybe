import { ServerClient } from 'postmark'

const postmark = new ServerClient(process.env.NX_POSTMARK_API_TOKEN || '')

export default postmark
