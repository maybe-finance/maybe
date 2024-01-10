import type { ReactElement } from 'react'
import { useMemo } from 'react'
import {
    WithSidebarLayout,
    AccountEditor,
    TransactionEditor,
    AccountSidebar,
} from '@maybe-finance/client/features'

import { Tab } from '@maybe-finance/design-system'
import { useQueryParam } from '@maybe-finance/client/shared'
import { useRouter } from 'next/router'

export default function DataEditor() {
    const currentTab = useQueryParam('tab', 'string')

    const router = useRouter()

    const selectedIndex = useMemo(() => {
        switch (currentTab) {
            case 'transactions':
                return 1
            default:
                return 0
        }
    }, [currentTab])

    return (
        <div>
            <h4>Fix my data</h4>
            <p className="text-base text-gray-100 mt-2">
                Is one of your accounts misclassified? A transaction showing the wrong category?
                Update your data below so we can show you the best insights possible.
            </p>
            <div className="mt-4">
                <Tab.Group
                    onChange={(idx) => {
                        switch (idx) {
                            case 0:
                                router.replace({ query: { tab: 'accounts' } })
                                break
                            case 1:
                                router.replace({ query: { tab: 'transactions' } })
                                break
                        }
                    }}
                    selectedIndex={selectedIndex}
                >
                    <Tab.List>
                        <Tab>Accounts</Tab>
                        <Tab>Transactions</Tab>
                    </Tab.List>
                    <Tab.Panels className="mt-4">
                        <Tab.Panel>{router.isReady && <AccountEditor />}</Tab.Panel>
                        <Tab.Panel>{router.isReady && <TransactionEditor />}</Tab.Panel>
                    </Tab.Panels>
                </Tab.Group>
            </div>
        </div>
    )
}

DataEditor.getLayout = function getLayout(page: ReactElement) {
    return <WithSidebarLayout sidebar={<AccountSidebar />}>{page}</WithSidebarLayout>
}
