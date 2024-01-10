import { useAccountApi } from '@maybe-finance/client/shared'
import { EditAsset } from './asset'
import { EditLiability } from './liability'
import { EditProperty } from './property'
import { EditVehicle } from './vehicle'
import { EditConnectedAccount } from './connected'

export default function EditAccount({ accountId }: { accountId?: number }) {
    const { useAccount } = useAccountApi()
    const accountQuery = useAccount(accountId!, { enabled: !!accountId })

    if (!accountId) return null

    if (accountQuery.data && accountQuery.data.type === 'LOAN') {
        return <EditLiability account={accountQuery.data} />
    }

    if (accountQuery.data && accountQuery.data.provider !== 'user') {
        return <EditConnectedAccount account={accountQuery.data} />
    }

    return (
        <div>
            {accountQuery.data && accountQuery.data.provider === 'user' ? (
                <div>
                    {accountQuery.data.type === 'PROPERTY' && (
                        <EditProperty account={accountQuery.data} />
                    )}

                    {accountQuery.data.type === 'VEHICLE' && (
                        <EditVehicle account={accountQuery.data} />
                    )}

                    {accountQuery.data.type === 'OTHER_ASSET' && (
                        <EditAsset account={accountQuery.data} />
                    )}

                    {['OTHER_LIABILITY', 'CREDIT'].includes(accountQuery.data.type) && (
                        <EditLiability account={accountQuery.data} />
                    )}
                </div>
            ) : (
                <p className="text-gray-50 animate-pulse">Loading account details...</p>
            )}
        </div>
    )
}
