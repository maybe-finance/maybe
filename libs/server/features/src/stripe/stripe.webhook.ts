import type { Logger } from 'winston'
import type Stripe from 'stripe'
import type { PrismaClient } from '@prisma/client'
import { DateTime } from 'luxon'

export interface IStripeWebhookHandler {
    handleWebhook(event: Stripe.Event): Promise<void>
}

export class StripeWebhookHandler implements IStripeWebhookHandler {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly stripe: Stripe
    ) {}

    async handleWebhook(event: Stripe.Event) {
        switch (event.type) {
            case 'checkout.session.completed': {
                const session = event.data.object as Stripe.Checkout.Session

                if (!session.subscription || !session.client_reference_id) return

                const subscription = await this.stripe.subscriptions.retrieve(
                    session.subscription as string
                )

                await this.prisma.user.updateMany({
                    where: {
                        auth0Id: session.client_reference_id,
                    },
                    data: {
                        trialEnd: null,
                        stripeCustomerId: subscription.customer as string,
                        stripeSubscriptionId: subscription.id,
                        stripePriceId: subscription.items.data[0]?.price.id,
                        stripeCurrentPeriodEnd: new Date(subscription.current_period_end * 1000),
                        stripeCancelAt: subscription.cancel_at
                            ? new Date(subscription.cancel_at * 1000)
                            : null,
                    },
                })

                break
            }
            case 'customer.subscription.created':
            case 'customer.subscription.updated': {
                const subscription = event.data.object as Stripe.Subscription

                await this.prisma.user.updateMany({
                    where: {
                        stripeCustomerId: subscription.customer as string,
                    },
                    data: {
                        trialEnd: null,
                        stripeSubscriptionId: subscription.id,
                        stripePriceId: subscription.items.data[0]?.price.id,
                        stripeCurrentPeriodEnd: new Date(subscription.current_period_end * 1000),
                        stripeCancelAt: subscription.cancel_at
                            ? new Date(subscription.cancel_at * 1000)
                            : null,
                    },
                })

                break
            }
            case 'customer.subscription.deleted': {
                const subscription = event.data.object as Stripe.Subscription

                await this.prisma.user.updateMany({
                    where: {
                        stripeSubscriptionId: subscription.id,
                    },
                    data: {
                        stripeSubscriptionId: null,
                        stripePriceId: null,
                        stripeCurrentPeriodEnd: null,
                        stripeCancelAt: DateTime.now().toJSDate(),
                    },
                })

                break
            }
            case 'customer.deleted': {
                const customer = event.data.object as Stripe.Customer

                await this.prisma.user.updateMany({
                    where: {
                        stripeCustomerId: customer.id,
                    },
                    data: {
                        stripeCustomerId: null,
                        stripeSubscriptionId: null,
                        stripePriceId: null,
                        stripeCurrentPeriodEnd: null,
                        stripeCancelAt: null,
                    },
                })
                break
            }
            default: {
                this.logger.warn('Unhandled Stripe event', { event })
                break
            }
        }
    }
}
