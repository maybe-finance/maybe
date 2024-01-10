import type { ReactElement } from 'react'
import { useUserApi, useQueryParam, BrowserUtil } from '@maybe-finance/client/shared'
import {
    AccountSidebar,
    BillingPreferences,
    GeneralPreferences,
    SecurityPreferences,
    UserDetails,
    WithSidebarLayout,
} from '@maybe-finance/client/features'
import { Button, Tab } from '@maybe-finance/design-system'
import { RiAttachmentLine } from 'react-icons/ri'
import { useRouter } from 'next/router'
import Script from 'next/script'

export default function SettingsPage() {
    const { useNewestAgreements } = useUserApi()
    const signedAgreements = useNewestAgreements('user')

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
                        <Tab>Documents</Tab>
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
                            {signedAgreements.data ? (
                                <div className="max-w-lg border border-gray-600 px-4 py-3 rounded text-base">
                                    <ul>
                                        {signedAgreements.data.map((agreement) => (
                                            <li
                                                key={agreement.id}
                                                className="flex items-center justify-between"
                                            >
                                                <div className="flex w-0 flex-1 items-center">
                                                    <RiAttachmentLine
                                                        className="h-4 w-4 shrink-0 text-gray-100"
                                                        aria-hidden="true"
                                                    />
                                                    <span className="ml-2 w-0 flex-1 truncate text-gray-25">
                                                        {BrowserUtil.agreementName(agreement.type)}
                                                    </span>
                                                </div>
                                                <Button
                                                    as="a"
                                                    variant="link"
                                                    target="_blank"
                                                    href={agreement.url}
                                                >
                                                    View
                                                </Button>
                                            </li>
                                        ))}
                                    </ul>
                                </div>
                            ) : (
                                <p className="text-gray-50">No documents found</p>
                            )}
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
