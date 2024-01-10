import { init } from 'launchdarkly-node-server-sdk'
import env from '../../env'

const ldClient = init(env.NX_LD_SDK_KEY, { offline: process.env.NODE_ENV === 'test' })

export default ldClient
