import type { ReactElement } from 'react'
import {  useQueryParam } from '@maybe-finance/client/shared'
import {
    AccountSidebar,
    BillingPreferences,
    GeneralPreferences,
    SecurityPreferences,
    UserDetails,
    WithSidebarLayout,
} from '@maybe-finance/client/features'
import {  Tab } from '@maybe-finance/design-system'
import { useRouter } from 'next/router'
import Script from 'next/script'

export default function SettingsPage() {
    const router = useRouter()

    const tabs = ['details', 'notifications', 'security', 'documents', 'billing']

    const currentTab = useQueryParam('tab', 'string')

    return (
        <>
            <Script
                src="https://cdnjs.cloudflare.com/ajax/libs/zxcvbn/4.4.2/zxcvbn.js"
                strategy="lazyOnload"
            />
            <section className="space-y-4">
                <h3>Settings</h3>
                <Tab.Group
                    onChange={(idx) => {
                        router.replace({ query: { tab: tabs[idx] } })
                    }}
                    selectedIndex={tabs.findIndex((tab) => tab === currentTab)}
                >
                    <Tab.List>
                        <Tab>Details</Tab>
                        <Tab>Notifications</Tab>
                        <Tab>Security</Tab>
                        <Tab>Billing</Tab>
                    </Tab.List>
                    <Tab.Panels>
                        <Tab.Panel>
                            <UserDetails />
                        </Tab.Panel>
                        <Tab.Panel>
                            <div className="mt-6 max-w-lg text-base">
                                <GeneralPreferences />
                            </div>
                        </Tab.Panel>
                        <Tab.Panel>
                            <div className="mt-6 max-w-lg">
                                <SecurityPreferences />
                            </div>
                        </Tab.Panel>
                        <Tab.Panel>
                            <BillingPreferences />
                        </Tab.Panel>
                    </Tab.Panels>
                </Tab.Group>
            </section>
        </>
    )
}

SettingsPage.getLayout = function getLayout(page: ReactElement) {
    return <WithSidebarLayout sidebar={<AccountSidebar />}>{page}</WithSidebarLayout>
}
