import type { User as Auth0UserClient } from '@auth0/auth0-react'
import type { Identity, User as Auth0UserServer } from 'auth0'
import type {
    AccountCategory,
    AccountClassification,
    Holding,
    Prisma,
    Security,
    User as PrismaUser,
    AuthUser,
} from '@prisma/client'
import type { Institution } from 'plaid'
import type { TimeSeries, TimeSeriesResponseWithDetail, Trend } from './general-types'
import type { DateTime } from 'luxon'

/**
 * ================================================================
 * ======                      User                          ======
 * ================================================================
 */

export type User = Omit<PrismaUser, 'riskAnswers'> & { riskAnswers: RiskAnswer[] }
export type UpdateUser = Partial<
    Prisma.UserUncheckedUpdateInput & {
        monthlyDebtUser: number | null
        monthlyIncomeUser: number | null
        monthlyExpensesUser: number | null
    }
>

/**
 * ================================================================
 * ======                 Auth User                          ======
 * ================================================================
 */

export type { AuthUser }

/**
 * ================================================================
 * ======                   Net Worth                        ======
 * ================================================================
 */
export type NetWorthTimeSeriesData = {
    date: string // yyyy-mm-dd
    netWorth: Prisma.Decimal
    assets: Prisma.Decimal
    liabilities: Prisma.Decimal
    categories: Partial<Record<AccountCategory, Prisma.Decimal>>
}

export type NetWorthTimeSeriesResponse = TimeSeriesResponseWithDetail<
    TimeSeries<NetWorthTimeSeriesData>
>

/**
 * ================================================================
 * ======                     Insights                       ======
 * ================================================================
 */

export type UserInsights = {
    netWorthToday: Prisma.Decimal
    netWorth: {
        yearly: Trend
        monthly: Trend
        weekly: Trend
    }
    safetyNet: {
        months: Prisma.Decimal
        spending: Prisma.Decimal
    }
    debtIncome: {
        ratio: Prisma.Decimal
        debt: Prisma.Decimal
        income: Prisma.Decimal
        user: {
            debt: Prisma.Decimal | null
            income: Prisma.Decimal | null
        }
        calculated: {
            debt: Prisma.Decimal
            income: Prisma.Decimal
        }
    }
    debtAsset: {
        ratio: Prisma.Decimal
        debt: Prisma.Decimal
        asset: Prisma.Decimal
    }
    accountSummary: {
        classification: AccountClassification
        category: AccountCategory
        balance: Prisma.Decimal
        allocation: Prisma.Decimal
    }[]
    assetSummary: {
        liquid: {
            amount: Prisma.Decimal
            percentage: Prisma.Decimal
        }
        illiquid: {
            amount: Prisma.Decimal
            percentage: Prisma.Decimal
        }
        yielding: {
            amount: Prisma.Decimal
            percentage: Prisma.Decimal
        }
    }
    debtSummary: {
        good: {
            amount: Prisma.Decimal
            percentage: Prisma.Decimal
        }
        bad: {
            amount: Prisma.Decimal
            percentage: Prisma.Decimal
        }
        total: {
            amount: Prisma.Decimal
            percentage: Prisma.Decimal
        }
    }
    holdingBreakdown: {
        category: 'stocks' | 'fixed_income' | 'cash' | 'crypto' | 'other'
        value: Holding['value']
        allocation: Prisma.Decimal
        holdings: {
            security: Pick<Security, 'id' | 'symbol' | 'name'>
            value: Holding['value']
            allocation: Prisma.Decimal
        }[]
    }[]
    transactionSummary: {
        income: Prisma.Decimal
        expenses: Prisma.Decimal
        payments: Prisma.Decimal
    }
    transactionBreakdown: {
        category: string | null
        amount: Prisma.Decimal
        avg_6mo: Prisma.Decimal
    }[]
}

/**
 * ================================================================
 * ======               User Profile/Account                 ======
 * ================================================================
 */

// Arbitrary custom namespaces to avoid collision with Auth0 properties
export enum Auth0CustomNamespace {
    Email = 'https://maybe.co/email',
    Picture = 'https://maybe.co/picture',
    Roles = 'https://maybe.co/roles',
    UserMetadata = 'https://maybe.co/user-metadata',
    AppMetadata = 'https://maybe.co/app-metadata',

    // A convenience property (so we dont have to parse the Auth0 `identities` array every time)
    PrimaryIdentity = 'https://maybe.co/primary-identity',
}

// Maybe's "normalized" Auth0 `user.user_metadata` object
export type MaybeUserMetadata = Partial<{
    enrolled_mfa: boolean
    hasDuplicateAccounts: boolean
    shouldPromptUserAccountLink: boolean
}>

// Maybe's "normalized" Auth0 `user.app_metadata` object
export type MaybeAppMetadata = {}

// The custom roles we have defined in Auth0
export type UserRole = 'Admin' | 'CIUser'

export type PrimaryAuth0Identity = Partial<{
    connection: string
    provider: string
    isSocial: boolean
}>

// Added to access and ID tokens via Auth0 rules
export type MaybeCustomClaims = {
    [Auth0CustomNamespace.Email]?: string | null
    [Auth0CustomNamespace.Picture]?: string | null
    [Auth0CustomNamespace.Roles]?: UserRole[]
    [Auth0CustomNamespace.UserMetadata]?: MaybeUserMetadata
    [Auth0CustomNamespace.AppMetadata]?: MaybeAppMetadata
    [Auth0CustomNamespace.PrimaryIdentity]?: PrimaryAuth0Identity
}

export type Auth0ReactUser = Auth0UserClient & MaybeCustomClaims
export type Auth0User = Auth0UserServer<MaybeAppMetadata, MaybeUserMetadata>
export type Auth0Profile = Auth0User & {
    primaryIdentity: Identity // actual
    secondaryIdentities: Identity[] // linked
    suggestedIdentities: Identity[] // potential links
    autoPromptEnabled: boolean
    socialOnlyUser: boolean
    mfaEnabled: boolean
}

export type UpdateAuth0User = { enrolled_mfa: boolean }

export interface PasswordReset {
    currentPassword: string
    newPassword: string
}

export type LinkAccountStatus = {
    autoPromptEnabled: boolean
    suggestedUsers: Auth0User[]
}

export interface LinkAccounts {
    secondaryJWT: string
    secondaryProvider: string
}

export interface UnlinkAccount {
    secondaryAuth0Id: string
    secondaryProvider: string
}

export type UserSubscription = {
    subscribed: boolean
    trialing: boolean
    canceled: boolean

    trialEnd: DateTime | null
    cancelAt: DateTime | null

    currentPeriodEnd: DateTime | null
}

export type UserMemberCardDetails = {
    memberNumber: number
    name: string
    title: string
    joinDate: Date
    maybe: string
    cardUrl: string
    imageUrl: string
}

export type RiskQuestionChoice = {
    key: string
    text: string
    riskScore: number
}

export type RiskQuestion = {
    key: string
    text: string
    choices: RiskQuestionChoice[]
}

export type RiskAnswer = {
    questionKey: string
    choiceKey: string
}

/**
 * main - the fullscreen "takeover" every user must go through
 * sidebar - the post-onboarding sidebar for connecting accounts
 */
export type OnboardingFlow = 'main' | 'sidebar'

export type OnboardingStep = {
    key: string
    title: string
    isComplete: boolean
    isMarkedComplete: boolean
    group?: string
    ctaPath?: string
}

export type OnboardingResponse = {
    steps: OnboardingStep[]
    currentStep: OnboardingStep | null
    progress: {
        completed: number
        total: number
        percent: number
    }
    isComplete: boolean
    isMarkedComplete: boolean
}

/**
 * ================================================================
 * ======                 Plaid Connections                  ======
 * ================================================================
 */
export type PlaidLinkUpdateMode = 'reconnect' | 'new-accounts'

// Used for /create/link/token when user is connecting a bank account
export interface LinkConfig {
    token: string
}

export type PublicTokenExchange = LinkConfig & {
    institution: Institution
}
