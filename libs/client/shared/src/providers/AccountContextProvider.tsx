import type { SetStateAction, Dispatch, ReactNode, PropsWithChildren } from 'react'
import type { SharedType } from '@maybe-finance/shared'
import type { DateRange } from '@maybe-finance/design-system'
import { createContext, useState, useContext } from 'react'
import { DateTime } from 'luxon'
import type { AccountCategory } from '@prisma/client'

export type AccountValuationFields = {
    startDate: string | null
    originalBalance: number | null
    currentBalance: number | null
}

// Stock
export type StockValuationFields = {
    startDate: string | null
    originalBalance: number | null
    shares: number | null
}

type StockMetadataValues = {
    account_id: number | null
    stock: string | null
}

export type CreateStockFields = StockMetadataValues & StockValuationFields
// STOCKTODO - Make sure that the UpdateStockFields is correct.
export type UpdateStockFields = StockMetadataValues

// Property
type PropertyMetadataValues = {
    line1: string
    city: string
    state: string
    country: string
    zip: string
}
export type CreatePropertyFields = PropertyMetadataValues & AccountValuationFields
export type UpdatePropertyFields = PropertyMetadataValues

// Vehicle
type VehicleValues = { make: string; model: string; year: string }

export type CreateVehicleFields = VehicleValues & AccountValuationFields
export type UpdateVehicleFields = VehicleValues

// Other
type AssetValues = { name: string; categoryUser: AccountCategory }
export type CreateAssetFields = AssetValues & AccountValuationFields
export type UpdateAssetFields = AssetValues

// Loan
type LiabilityValues = { name: string; categoryUser: AccountCategory }
type LoanValues = {
    name: string
    maturityDate: string
    interestType: SharedType.Loan['interestRate']['type'] | null
    loanType: SharedType.Loan['loanDetail']['type'] | null
    interestRate: number | null
}
export type CreateLiabilityFields = LiabilityValues & LoanValues & AccountValuationFields
export type UpdateLiabilityFields = CreateLiabilityFields

type AccountManager =
    | { view: 'idle' }
    | { view: 'add-teller' }
    | { view: 'add-account' }
    | { view: 'add-property'; defaultValues: Partial<CreatePropertyFields> }
    // STOCKTODO - Create the necessary stock types here
    | { view: 'add-stock'; defaultValues: Partial<CreateStockFields> }
    | { view: 'add-vehicle'; defaultValues: Partial<CreateVehicleFields> }
    | { view: 'add-asset'; defaultValues: Partial<CreateAssetFields> }
    | { view: 'add-liability'; defaultValues: Partial<CreateLiabilityFields> }
    | { view: 'edit-account'; accountId: number }
    | { view: 'delete-account'; accountId: number; accountName: string; onDelete?: () => void }
    | { view: 'custom'; component: ReactNode }

export interface AccountContext {
    accountManager: AccountManager
    setAccountManager: Dispatch<SetStateAction<AccountManager>>
    addAccount(): void
    editAccount(account: SharedType.Account): void
    deleteAccount(account: SharedType.Account, onDelete?: () => void): void
    dateRange: DateRange
    setDateRange(newDateRange: DateRange | ((prevDateRange: DateRange) => DateRange)): void
}

export const AccountContext = createContext<AccountContext | undefined>(undefined)

export function useAccountContext() {
    const context = useContext(AccountContext)

    if (!context) {
        throw new Error('useAccountContext() must be used within <AccountContextProvider>')
    }

    return context
}

export function AccountContextProvider({ children }: PropsWithChildren<{}>) {
    const [accountManager, setAccountManager] = useState<AccountManager>({
        view: 'idle',
    })

    // Homepage and sidebar shared date range (defaults to "Prior month")
    const [dateRange, setDateRange] = useState<DateRange>({
        start: DateTime.now().minus({ days: 30 }).toISODate(),
        end: DateTime.now().toISODate(),
    })

    return (
        <AccountContext.Provider
            value={{
                dateRange,
                setDateRange,
                accountManager,
                setAccountManager,
                addAccount: () => setAccountManager({ view: 'add-account' }),
                editAccount: (account) =>
                    setAccountManager({ view: 'edit-account', accountId: account.id }),
                deleteAccount: (account, onDelete) =>
                    setAccountManager({
                        view: 'delete-account',
                        accountId: account.id,
                        accountName: account.name,
                        onDelete,
                    }),
            }}
        >
            {children}
        </AccountContext.Provider>
    )
}
