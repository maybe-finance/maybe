import type { Subjects } from '@casl/prisma'
import { PrismaAbility, accessibleBy } from '@casl/prisma'
import type { AbilityClass } from '@casl/ability'
import { AbilityBuilder, ForbiddenError } from '@casl/ability'
import type {
    User,
    Account,
    AccountBalance,
    AccountConnection,
    Transaction,
    Valuation,
    Holding,
    InvestmentTransaction,
    Security,
    SecurityPricing,
    Institution,
    ProviderInstitution,
    Plan,
} from '@prisma/client'
import { AuthUserRole } from '@prisma/client'

type CRUDActions = 'create' | 'read' | 'update' | 'delete'
type AppActions = CRUDActions | 'manage'

type PrismaSubjects = Subjects<{
    User: User
    Account: Account
    AccountBalance: AccountBalance
    AccountConnection: AccountConnection
    Transaction: Transaction
    Valuation: Valuation
    Security: Security
    SecurityPricing: SecurityPricing
    Holding: Holding
    InvestmentTransaction: InvestmentTransaction
    Institution: Institution
    ProviderInstitution: ProviderInstitution
    Plan: Omit<Plan, 'events'>
}>
type AppSubjects = PrismaSubjects | 'all'

type AppAbility = PrismaAbility<[AppActions, AppSubjects]>

export default function defineAbilityFor(user: (Pick<User, 'id'> & { role: AuthUserRole }) | null) {
    const { can, build } = new AbilityBuilder(PrismaAbility as AbilityClass<AppAbility>)

    if (user) {
        if (user.role === AuthUserRole.admin) {
            can('manage', 'Account')
            can('manage', 'AccountConnection')
            can('manage', 'Valuation')
            can('manage', 'User')
            can('manage', 'Institution')
            can('manage', 'Plan')
            can('manage', 'Holding')
        }

        // Account
        can('create', 'Account')
        can('read', 'Account', { userId: user.id })
        can('read', 'Account', { accountConnection: { is: { userId: user.id } } })
        can('update', 'Account', { userId: user.id })
        can('update', 'Account', { accountConnection: { is: { userId: user.id } } })
        can('delete', 'Account', { userId: user.id })
        can('delete', 'Account', { accountConnection: { is: { userId: user.id } } })

        // Valuation
        can('create', 'Valuation')
        can('read', 'Valuation', { account: { is: { userId: user.id } } })
        can('update', 'Valuation', { account: { is: { userId: user.id } } })
        can('delete', 'Valuation', { account: { is: { userId: user.id } } })

        // AccountConnection
        can('create', 'AccountConnection')
        can('read', 'AccountConnection', { userId: user.id })
        can('update', 'AccountConnection', { userId: user.id })
        can('delete', 'AccountConnection', { userId: user.id })

        // User
        can('read', 'User', { id: user.id })
        can('update', 'User', { id: user.id })
        can('delete', 'User', { id: user.id })

        // Institution
        can('read', 'Institution')

        // Security
        can('read', 'Security')

        // Transaction
        can('read', 'Transaction', { account: { is: { userId: user.id } } })
        can('read', 'Transaction', {
            account: { is: { accountConnection: { is: { userId: user.id } } } },
        })
        can('update', 'Transaction', { account: { is: { userId: user.id } } })
        can('update', 'Transaction', {
            account: { is: { accountConnection: { is: { userId: user.id } } } },
        })

        // Holding
        can('read', 'Holding', { account: { is: { userId: user.id } } })
        can('read', 'Holding', {
            account: { is: { accountConnection: { is: { userId: user.id } } } },
        })
        can('update', 'Holding', { account: { is: { userId: user.id } } })
        can('update', 'Holding', {
            account: { is: { accountConnection: { is: { userId: user.id } } } },
        })

        // Plan
        can('create', 'Plan')
        can('read', 'Plan', { userId: user.id })
        can('update', 'Plan', { userId: user.id })
        can('delete', 'Plan', { userId: user.id })
    }

    const ability = build()

    return {
        can: ability.can,
        throwUnlessCan: (...args: Parameters<AppAbility['can']>) => {
            ForbiddenError.from(ability).throwUnlessCan(...args)
        },
        where: accessibleBy(ability),
    }
}
