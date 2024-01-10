import Stripe from 'stripe'
import env from '../../env'

const stripe = new Stripe(env.NX_STRIPE_SECRET_KEY, { apiVersion: '2022-08-01' })

export default stripe
