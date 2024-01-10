import type { SharedType } from '@maybe-finance/shared'
import { DateTime } from 'luxon'
import maxBy from 'lodash/maxBy'
import { useLastUpdated, useAccountContext } from '@maybe-finance/client/shared'
import Account from './Account'
import { AccountGroup } from './AccountGroup'

type ManualAccountGroupProps = {
    title: string
    subtitle: string
    accounts: SharedType.Account[]
}

export function ManualAccountGroup({ title, accounts }: ManualAccountGroupProps) {
    const { editAccount } = useAccountContext()

    // Use the most recently updated manual account in the group
    const lastUpdatedString = useLastUpdated(
        DateTime.fromJSDate(maxBy(accounts, (a) => a.updatedAt)?.updatedAt || new Date())
    )

    return (
        <AccountGroup
            title={title}
            subtitle={lastUpdatedString}
            content={
                <ul>
                    {accounts.map((account) => (
                        <Account
                            key={account.id}
                            account={account}
                            canDelete
                            onEdit={() => editAccount(account)}
                            showAccountDescription={false}
                        />
                    ))}
                </ul>
            }
        />
    )
}
