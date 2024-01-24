import { useAccountContext } from '@maybe-finance/client/shared'
import { Dialog } from '@maybe-finance/design-system'

import AccountTypeSelector from './AccountTypeSelector'
import { AddAsset } from './asset'
import { AddLiability } from './liability'
import { AddProperty } from './property'
import { AddVehicle } from './vehicle'
import EditAccount from './EditAccount'
import { DeleteAccount } from './DeleteAccount'
import { RiArrowLeftLine } from 'react-icons/ri'
import { useEffect, useMemo, useState } from 'react'

export function AccountsManager() {
    const { accountManager: am, setAccountManager } = useAccountContext()

    const [subView, setSubView] = useState('default')

    useEffect(() => {
        if (am.view === 'idle') {
            setSubView('default')
        }
    }, [am.view])

    const accountTitle = () => {
        switch (subView) {
            case 'banks':
                return 'Add bank'
            case 'crypto':
                return 'Add crypto'
            case 'brokerages':
                return 'Add investment'
            default:
                return 'Add account'
        }
    }

    const view = useMemo(() => {
        switch (am.view) {
            case 'add-account':
                return {
                    title: accountTitle(),
                    component: <AccountTypeSelector view={subView} onViewChange={setSubView} />,
                }
            case 'edit-account':
                return {
                    title: 'Edit account',
                    component: <EditAccount accountId={am.accountId} />,
                }
            case 'delete-account':
                return {
                    title: 'Delete account',
                    component: (
                        <DeleteAccount
                            accountId={am.accountId}
                            accountName={am.accountName}
                            onDelete={am.onDelete}
                        />
                    ),
                }
            case 'add-asset':
                return {
                    title: 'Manual asset',
                    component: <AddAsset defaultValues={am.defaultValues} />,
                }
            case 'add-liability':
                return {
                    title: 'Manual debt',
                    component: <AddLiability defaultValues={am.defaultValues} />,
                }
            case 'add-property':
                return {
                    title: 'Add real estate',
                    component: <AddProperty defaultValues={am.defaultValues} />,
                }
            case 'add-vehicle':
                return {
                    title: 'Add vehicle',
                    component: <AddVehicle defaultValues={am.defaultValues} />,
                }
            case 'add-stock':
                return {
                    title: 'Add investment',
                    component: <></>,
                }
            case 'custom':
                return { title: 'Custom account', component: am.component }
            default:
                return null
        }
    }, [am, subView])

    if (!view) return null

    return (
        <Dialog
            isOpen={am.view !== 'idle'}
            onClose={() => setAccountManager({ view: 'idle' })}
            showCloseButton={am.view !== 'delete-account'}
        >
            <Dialog.Title>
                <div className="flex items-center">
                    {!(am.view === 'add-account' && subView === 'default') &&
                        am.view !== 'delete-account' && (
                            <button
                                type="button"
                                className="h-8 w-8 mr-3 flex items-center justify-center bg-transparent text-gray-50 hover:bg-gray-500 rounded focus:bg-gray-400 focus:outline-none"
                                onClick={() => {
                                    setAccountManager({ view: 'add-account' })
                                    setSubView('default')
                                }}
                            >
                                <RiArrowLeftLine className="h-6 w-6" />
                            </button>
                        )}
                    {view.title}
                </div>
            </Dialog.Title>
            <Dialog.Content className="mt-2">{view.component}</Dialog.Content>
        </Dialog>
    )
}
