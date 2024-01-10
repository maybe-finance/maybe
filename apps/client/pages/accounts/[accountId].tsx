import type { ReactElement } from 'react'
import type { SharedType } from '@maybe-finance/shared'

import { useEffect, useState } from 'react'
import {
    WithSidebarLayout,
    ValuationList,
    TransactionList,
    AccountSidebar,
    InlineQuestionCardGroup,
} from '@maybe-finance/client/features'
import { useRouter } from 'next/router'
import { DateTime } from 'luxon'
import {
    MainContentOverlay,
    useAccountApi,
    useQueryParam,
    useUserAccountContext,
} from '@maybe-finance/client/shared'
import { DefaultView, LoanView } from '../../components/account-views'

import InvestmentView from '../../components/account-views/InvestmentView'
import { RiArrowUpLine, RiFolder4Line, RiMoneyDollarBoxLine, RiPieChartLine } from 'react-icons/ri'

const initialRange = {
    start: DateTime.now().minus({ days: 30 }).toISODate(),
    end: DateTime.now().toISODate(),
}

export default function AccountDetailPage() {
    const router = useRouter()
    const [range, setRange] = useState<SharedType.DateRange>(initialRange)

    const { useAccount, useAccountBalances } = useAccountApi()
    const { isReady, accountSyncing } = useUserAccountContext()

    const accountId = useQueryParam('accountId', 'number')!
    const accountQuery = useAccount(accountId, { enabled: !!accountId && isReady })
    const accountBalancesQuery = useAccountBalances(
        { id: accountId, ...range },
        { enabled: !!accountId && isReady }
    )

    const isSyncing = accountSyncing(accountId)
    const isLoading = accountQuery.isLoading || accountBalancesQuery.isLoading || isSyncing
    const isError = accountQuery.isError || accountBalancesQuery.isError

    useEffect(() => {
        setRange(initialRange)
    }, [accountId])

    if (accountQuery.error || accountBalancesQuery.error) {
        return (
            <MainContentOverlay
                title="Unable to load account"
                actionText="Back home"
                onAction={() => {
                    router.push('/')
                }}
            >
                <p>
                    We&rsquo;re having some trouble loading this account. Please contact us if the
                    issue persists...
                </p>
            </MainContentOverlay>
        )
    }

    switch (accountQuery.data?.type) {
        case 'LOAN':
            return (
                <LoanView
                    account={accountQuery.data}
                    balances={accountBalancesQuery.data}
                    dateRange={range}
                    onDateChange={setRange}
                    isLoading={isLoading}
                    isError={isError}
                />
            )
        case 'INVESTMENT':
            return (
                <InvestmentView
                    account={accountQuery.data}
                    balances={accountBalancesQuery.data}
                    dateRange={range}
                    onDateChange={setRange}
                    isLoading={isLoading}
                    isError={isError}
                />
            )
        case 'CREDIT':
        case 'DEPOSITORY':
            return (
                <DefaultView
                    account={accountQuery.data}
                    balances={accountBalancesQuery.data}
                    dateRange={range}
                    onDateChange={setRange}
                    getContent={(accountId) => {
                        return (
                            <>
                                <InlineQuestionCardGroup
                                    className="mb-10"
                                    id={`account_${accountId}`}
                                    heading="Ask My Advisor"
                                    subheading="Get an advisor to review this account and make adjustments for your goals and risk profile."
                                    accountId={accountId}
                                    questions={[
                                        {
                                            icon: RiPieChartLine,
                                            title: 'How can I ensure that my account is diversified with other assets to minimize risk?',
                                        },
                                        {
                                            icon: RiArrowUpLine,
                                            title: 'Is there anything I could be doing to maximize the earning potential of this account?',
                                        },
                                        {
                                            icon: RiFolder4Line,
                                            title: 'Are there any other financial products that could complement this account?',
                                        },
                                        {
                                            icon: RiMoneyDollarBoxLine,
                                            title: 'Are there any expense categories that stand out from the rest which I should look out for?',
                                        },
                                    ]}
                                />
                                <h5 className="uppercase mb-6">Transactions</h5>
                                <TransactionList accountId={accountId} />
                            </>
                        )
                    }}
                    isLoading={isLoading}
                    isError={isError}
                    selectableDateRanges={[
                        'last-7-days',
                        'last-30-days',
                        'last-90-days',
                        'last-365-days',
                        'this-year',
                    ]}
                />
            )
        default:
            return (
                <DefaultView
                    account={accountQuery.data}
                    balances={accountBalancesQuery.data}
                    dateRange={range}
                    onDateChange={setRange}
                    getContent={(accountId: number) => {
                        return (
                            <ValuationList
                                accountId={accountId}
                                negative={accountQuery.data?.classification === 'liability'}
                            />
                        )
                    }}
                    isLoading={isLoading}
                    isError={isError}
                />
            )
    }
}

AccountDetailPage.getLayout = function getLayout(page: ReactElement) {
    return <WithSidebarLayout sidebar={<AccountSidebar />}>{page}</WithSidebarLayout>
}
