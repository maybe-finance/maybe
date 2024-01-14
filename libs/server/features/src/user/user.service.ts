import type { AccountCategory, AccountType, PrismaClient, User } from '@prisma/client'
import type { Logger } from 'winston'
import type { PurgeUserQueue, SyncUserQueue } from '@maybe-finance/server/shared'
import type Stripe from 'stripe'
import type { IBalanceSyncStrategyFactory } from '../account-balance'
import type { IAccountQueryService } from '../account'
import type { SharedType } from '@maybe-finance/shared'
import { DateTime } from 'luxon'
import { DbUtil } from '@maybe-finance/server/shared'
import { DateUtil } from '@maybe-finance/shared'
import { flatten } from 'lodash'
import { Onboarding, type OnboardingState, type Step } from './onboarding.service'

export type MainOnboardingUser = Pick<
    User,
    'dob' | 'household' | 'maybeGoals' | 'firstName' | 'lastName' | 'name'
> & {
    emailVerified: boolean
    isAppleIdentity: boolean
    onboarding: OnboardingState['main']
    accountConnections: { accounts: { id: number }[] }[]
    accounts: { id: number }[]
}

export type SidebarOnboardingUser = {
    onboarding: OnboardingState['sidebar']
    accountConnections: {
        accounts: {
            type: AccountType
            category: AccountCategory
        }[]
    }[]
    accounts: {
        type: AccountType
        category: AccountCategory
    }[]
    _count: {
        plans: number
    }
}

export interface IUserService {
    get(id: User['id']): Promise<User>
    sync(id: User['id']): Promise<User>
    syncBalances(id: User['id']): Promise<User>
    delete(id: User['id']): Promise<User>
}

export class UserService implements IUserService {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly queryService: IAccountQueryService,
        private readonly balanceSyncStrategyFactory: IBalanceSyncStrategyFactory,
        private readonly syncQueue: SyncUserQueue,
        private readonly purgeQueue: PurgeUserQueue,
        private readonly stripe: Stripe
    ) {}

    async get(id: User['id']) {
        return this.prisma.user.findUniqueOrThrow({
            where: { id },
        })
    }

    async getAuthProfile(id: User['id']): Promise<SharedType.AuthUser> {
        const user = await this.get(id)
        return this.prisma.authUser.findUniqueOrThrow({
            where: { id: user.authId },
        })
    }

    async sync(id: User['id']) {
        const user = await this.get(id)
        await this.syncQueue.add('sync-user', { userId: user.id })
        return user
    }

    async syncBalances(id: User['id']) {
        const user = await this.prisma.user.findUniqueOrThrow({
            where: { id },
            include: {
                accounts: true,
                accountConnections: {
                    select: {
                        accounts: true,
                    },
                },
            },
        })

        const profiler = this.logger.startTimer()

        await Promise.all([
            ...user.accounts.map((account) =>
                this.balanceSyncStrategyFactory.for(account).syncAccountBalances(account)
            ),
            ...user.accountConnections.flatMap((connection) =>
                connection.accounts.map((account) =>
                    this.balanceSyncStrategyFactory.for(account).syncAccountBalances(account)
                )
            ),
        ])

        profiler.done({ message: `Synced user ${id} balances` })

        return user
    }

    async update(id: User['id'], data: SharedType.UpdateUser) {
        return this.prisma.user.update({
            where: { id },
            data,
        })
    }

    async delete(id: User['id']) {
        const user = await this.get(id)

        // Delete Stripe customer, ending any active subscriptions
        if (user.stripeCustomerId) await this.stripe.customers.del(user.stripeCustomerId)

        // Delete user from Auth so that it cannot be accessed in a partially-purged state
        // TODO: Update this to use new Auth
        this.logger.info(`Removing user ${user.id} from Auth (${user.authId})`)
        await this.prisma.authUser.delete({ where: { id: user.authId } })

        await this.purgeQueue.add('purge-user', { userId: user.id })

        return user
    }

    async getNetWorth(
        userId: User['id'],
        date: string = DateTime.utc().plus({ days: 1 }).toISODate() // default to one day here to ensure we're grabbing the most recent date's net worth
    ): Promise<SharedType.NetWorthTimeSeriesData | undefined> {
        const [netWorth] = await this.queryService.getNetWorthSeries({ userId }, date, date, 'days')

        return netWorth
    }

    async getNetWorthSeries(
        userId: User['id'],
        start = DateTime.utc().minus({ years: 2 }).toISODate(),
        end = DateTime.utc().toISODate(),
        interval?: SharedType.TimeSeriesInterval
    ): Promise<SharedType.NetWorthTimeSeriesResponse> {
        interval = interval ?? DateUtil.calculateTimeSeriesInterval(start, end)

        const [series, today, minDate] = await Promise.all([
            this.queryService.getNetWorthSeries({ userId }, start, end, interval),
            this.getNetWorth(userId),
            this.getOldestBalanceDate(userId),
        ])

        return {
            series: {
                interval,
                start,
                end,
                data: series,
            },
            today,
            minDate,
            trend:
                series.length > 0
                    ? DbUtil.calculateTrend(series[0].netWorth, series[series.length - 1].netWorth)
                    : { amount: null, percentage: null, direction: 'flat' },
        }
    }

    private async getOldestBalanceDate(userId: User['id']): Promise<string> {
        const [{ min_start_date }] = await this.prisma.$queryRaw<[{ min_start_date: Date | null }]>`
            SELECT
                LEAST(
                    MIN(a.start_date),
                    MIN(account_value_start_date(a.id))
                ) AS min_start_date
            FROM
                account a
                LEFT JOIN account_connection ac ON ac.id = a.account_connection_id
            WHERE
                (a.user_id = ${userId} OR ac.user_id = ${userId})
                AND a.is_active;
        `

        const minDate = DateTime.min(
            DateTime.utc().minus({ years: 2 }),
            ...(min_start_date ? [DateTime.fromJSDate(min_start_date, { zone: 'utc' })] : [])
        )

        return minDate.toISODate()
    }

    async getSubscription(userId: User['id']): Promise<SharedType.UserSubscription> {
        const {
            trialEnd: trialEndRaw,
            stripePriceId,
            stripeCurrentPeriodEnd,
            stripeCancelAt,
        } = await this.prisma.user.findUniqueOrThrow({
            select: {
                trialEnd: true,
                stripePriceId: true,
                stripeCurrentPeriodEnd: true,
                stripeCancelAt: true,
            },
            where: { id: userId },
        })

        const trialEnd = trialEndRaw ? DateTime.fromJSDate(trialEndRaw) : null

        const trialing = trialEnd != null && trialEnd.diffNow().milliseconds > 0

        const subscribed = !!stripePriceId || trialing
        const cancelAt = stripeCancelAt ? DateTime.fromJSDate(stripeCancelAt) : null

        return {
            subscribed,
            trialing,
            canceled: stripeCancelAt != null,

            currentPeriodEnd: stripeCurrentPeriodEnd
                ? DateTime.fromJSDate(stripeCurrentPeriodEnd)
                : null,
            trialEnd,
            cancelAt,
        }
    }

    async getMemberCard(memberId: string, clientUrl: string) {
        const {
            name,
            memberNumber,
            title,
            createdAt: joinDate,
            maybe,
        } = await this.prisma.user.findUniqueOrThrow({
            where: { memberId },
            select: {
                name: true,
                memberNumber: true,
                title: true,
                createdAt: true,
                maybe: true,
            },
        })

        const cardUrl = new URL(`/card/${memberId}`, clientUrl)

        const imageUrl = new URL('api/card', clientUrl)
        imageUrl.searchParams.append('name', name || 'Maybe User')
        imageUrl.searchParams.append('number', memberNumber.toString())
        imageUrl.searchParams.append('title', title ?? '')
        imageUrl.searchParams.append('date', joinDate.toISOString())

        return {
            memberNumber,
            name,
            title,
            joinDate,
            maybe,
            cardUrl: cardUrl.href,
            imageUrl: imageUrl.href,
        }
    }

    async buildMainOnboarding(userId: User['id']): Promise<SharedType.OnboardingResponse> {
        function markedComplete(user: MainOnboardingUser, step: Step<MainOnboardingUser>) {
            return (
                user.onboarding.steps.find((dbStep) => dbStep.key === step.key)?.markedComplete ??
                false
            )
        }

        const user = await this.prisma.user.findUniqueOrThrow({
            where: { id: userId },
            select: {
                authId: true,
                onboarding: true,
                dob: true,
                household: true,
                maybeGoals: true,
                firstName: true,
                lastName: true,
                name: true,
                accounts: { select: { id: true } },
                accountConnections: {
                    select: { accounts: { select: { id: true } } },
                },
            },
        })

        const authUser = await this.prisma.authUser.findUniqueOrThrow({
            where: { id: user.authId },
        })

        // NextAuth used DateTime for this field
        const email_verified = authUser.emailVerified === null ? false : true

        const typedOnboarding = user.onboarding as OnboardingState | null
        const onboardingState = typedOnboarding
            ? typedOnboarding.main
            : { markedComplete: false, steps: [] }

        const onboarding = new Onboarding<MainOnboardingUser>(
            {
                ...user,
                onboarding: onboardingState,
                emailVerified: email_verified,
                isAppleIdentity: false,
            },
            onboardingState.markedComplete
        )

        onboarding
            .addStep('intro')
            .setTitle((user) => `Hey ${user.firstName ?? 'there'}, meet Maybe`)
            .addToGroup('account')
            .completeIf(markedComplete)

        onboarding
            .addStep('profile')
            .setTitle((_) => "Let's complete your profile")
            .addToGroup('profile')
            .completeIf((user) => {
                return user.dob != null && user.household != null
            })

        onboarding
            .addStep('verifyEmail')
            .setTitle((_) => "Before we start, let's verify your email")
            .addToGroup('setup')
            .completeIf((user) => user.emailVerified)
            .excludeIf((user) => user.isAppleIdentity || true) // TODO: Needs email service to send, skip for now

        onboarding
            .addStep('firstAccount')
            .setTitle((_) => "Let's add your first account")
            .addToGroup('setup')
            .markedCompleteIf((user, step) => markedComplete(user, step))
            .completeIf((user, step) => {
                return (
                    user.accountConnections.length > 0 ||
                    user.accounts.length > 0 ||
                    markedComplete(user, step)
                )
            })

        onboarding
            .addStep('accountSelection')
            .setTitle((_) => 'What other accounts do you have?')
            .addToGroup('setup')
            .completeIf(markedComplete)

        onboarding
            .addStep('maybe')
            .setTitle((_) => "One more thing, what's your maybe?")
            .completeIf(markedComplete)

        onboarding
            .addStep('welcome')
            .setTitle((user) => {
                return `Welcome to Maybe${user.name ? `, ${user.name}` : '!'}`
            })
            .completeIf(markedComplete)

        return onboarding
    }

    async buildSidebarOnboarding(userId: User['id']): Promise<SharedType.OnboardingResponse> {
        function markedComplete(user: SidebarOnboardingUser, step: Step<SidebarOnboardingUser>) {
            return (
                user.onboarding.steps.find((dbStep) => dbStep.key === step.key)?.markedComplete ??
                false
            )
        }

        function stepUnregistered(user: SidebarOnboardingUser, step: Step<SidebarOnboardingUser>) {
            return user.onboarding.steps.findIndex((dbStep) => dbStep.key === step.key) < 0
        }

        function hasAccountType(
            user: SidebarOnboardingUser,
            types: AccountType | AccountType[],
            category?: {
                match?: AccountCategory
                exclude?: AccountCategory
            }
        ) {
            const accounts = [
                ...user.accounts,
                ...flatten(user.accountConnections.map((ac) => ac.accounts)),
            ]

            return (
                accounts.filter((a) => {
                    let match = Array.isArray(types) ? types.includes(a.type) : types === a.type

                    if (!match) return false

                    if (category) {
                        if (category.match) {
                            match = a.category === category.match
                        }

                        if (category.exclude) {
                            match = a.category !== category.exclude
                        }
                    }

                    return match
                }).length > 0
            )
        }

        const user = await this.prisma.user.findUniqueOrThrow({
            where: { id: userId },
            select: {
                onboarding: true,
                accounts: { select: { type: true, category: true } },
                accountConnections: {
                    select: { accounts: { select: { type: true, category: true } } },
                },
                _count: { select: { plans: true } },
            },
        })

        const typedOnboarding = user.onboarding as OnboardingState | null
        const onboardingState = typedOnboarding
            ? typedOnboarding.sidebar
            : { markedComplete: false, steps: [] }

        const onboarding = new Onboarding<SidebarOnboardingUser>(
            {
                ...user,
                onboarding: onboardingState,
            },
            onboardingState.markedComplete
        )

        onboarding
            .addStep('connect-depository')
            .setTitle((_) => 'Connect bank accounts')
            .addToGroup('accounts')
            .markedCompleteIf(markedComplete)
            .completeIf((user) => hasAccountType(user, 'DEPOSITORY'))
            .excludeIf(stepUnregistered)

        onboarding
            .addStep('connect-investment')
            .setTitle((_) => 'Connect investment accounts')
            .addToGroup('accounts')
            .markedCompleteIf(markedComplete)
            .completeIf((user) => hasAccountType(user, 'INVESTMENT'))
            .excludeIf(stepUnregistered)

        onboarding
            .addStep('connect-liability')
            .setTitle((_) => 'Connect credit card and loan accounts')
            .addToGroup('accounts')
            .markedCompleteIf(markedComplete)
            .completeIf((user) => hasAccountType(user, ['CREDIT', 'LOAN']))
            .excludeIf(stepUnregistered)

        onboarding
            .addStep('add-crypto')
            .setTitle((_) => 'Manually add crypto accounts')
            .addToGroup('accounts')
            .markedCompleteIf(markedComplete)
            .completeIf((user) => hasAccountType(user, 'OTHER_ASSET', { match: 'crypto' }))
            .excludeIf(stepUnregistered)

        onboarding
            .addStep('add-property')
            .setTitle((_) => 'Manually add real estate')
            .addToGroup('accounts')
            .markedCompleteIf(markedComplete)
            .completeIf((user) => hasAccountType(user, 'PROPERTY'))
            .excludeIf(stepUnregistered)

        onboarding
            .addStep('add-vehicle')
            .setTitle((_) => 'Manually add vehicle')
            .addToGroup('accounts')
            .markedCompleteIf(markedComplete)
            .completeIf((user) => hasAccountType(user, 'VEHICLE'))
            .excludeIf(stepUnregistered)

        onboarding
            .addStep('add-other')
            .addToGroup('accounts')
            .setTitle((_) => 'Manually add other assets and debts')
            .markedCompleteIf(markedComplete)
            .completeIf((user) =>
                hasAccountType(user, ['OTHER_ASSET', 'OTHER_LIABILITY'], {
                    exclude: 'crypto',
                })
            )
            .excludeIf(stepUnregistered)

        onboarding
            .addStep('create-plan')
            .addToGroup('bonus')
            .setTitle((_) => 'Setup a financial plan')
            .completeIf((user) => user._count.plans > 0)
            .setCTAPath('/plans')

        return onboarding
    }
}
