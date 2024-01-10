import { Fragment, useState } from 'react'
import Tippy from '@tippyjs/react/headless'
import orderBy from 'lodash/orderBy'
import type { IconType } from 'react-icons'
import {
    RiEditLine,
    RiLineChartLine,
    RiMoneyDollarBoxLine,
    RiScales3Line,
    RiShareBoxFill,
} from 'react-icons/ri'
import { GiPalmTree } from 'react-icons/gi'
import { NumberUtil, AccountUtil, DateUtil, ATAUtil, type SharedType } from '@maybe-finance/shared'
import { Button, Badge, Tab } from '@maybe-finance/design-system'
import TrendBadge from './TrendBadge'
import RiskSlider from './RiskSlider'
import type { RouterOutput } from '../lib/trpc'
import Link from 'next/link'
import EditUser from './EditUser'

const CLIENT_URL = process.env.NX_CLIENT_URL || 'http://localhost:4200'

const goals: Record<string, [IconType, string]> = {
    save: [RiMoneyDollarBoxLine, 'I want to save up for something'],
    retire: [GiPalmTree, 'I would like to retire comfortably'],
    debt: [RiScales3Line, 'I need to pay off debt'],
    invest: [RiLineChartLine, 'I need help investing'],
}

type Props = {
    conversation: RouterOutput['advisor']['conversations']['get']
}

export default function ConversationUserDetails({ conversation }: Props) {
    const [isEditing, setIsEditing] = useState(false)
    const {
        user: { insights, ...userProfile },
    } = conversation

    const riskProfile = ATAUtil.calcRiskProfile(
        ATAUtil.riskQuestions,
        (conversation.user.riskAnswers ?? []) as SharedType.RiskAnswer[]
    )

    return (
        <div className="flex flex-col divide-y divide-gray-700">
            <EditUser user={userProfile} isOpen={isEditing} onClose={() => setIsEditing(false)} />
            {/* Header */}
            <div className="h-16 px-6 shrink-0 flex items-center">
                <h2 className="text-xl font-bold font-display text-white">Details</h2>
            </div>

            {/* Status */}
            <div className="px-4 py-4 sm:px-6">
                <dl className="space-y-3">
                    <div className="grid grid-cols-3 items-center text-sm">
                        <dt className="text-gray-100">Status</dt>
                        <dd className="text-white sm:col-span-2">
                            <Badge
                                size="sm"
                                variant={conversation.status === 'open' ? 'teal' : 'red'}
                                className="uppercase"
                            >
                                {conversation.status}
                            </Badge>
                        </dd>
                    </div>
                    <div className="grid grid-cols-3 text-sm">
                        <dt className="text-gray-100">Assistants</dt>
                        <dd className="text-white sm:col-span-2">N/A</dd>
                    </div>

                    {conversation.accountId && (
                        <div className="grid grid-cols-3 text-sm">
                            <dt className="text-gray-100">Account</dt>
                            <dd className="text-white sm:col-span-2">
                                <a
                                    href={`${CLIENT_URL}/accounts/${conversation.accountId}`}
                                    target="_blank"
                                    rel="noreferrer"
                                >
                                    {conversation.accountId}
                                </a>
                            </dd>
                        </div>
                    )}

                    {conversation.planId && (
                        <div className="grid grid-cols-3 text-sm">
                            <dt className="text-gray-100">Plan</dt>
                            <dd className="text-white sm:col-span-2">
                                <a
                                    href={`${CLIENT_URL}/plans/${conversation.planId}`}
                                    target="_blank"
                                    rel="noreferrer"
                                >
                                    {conversation.planId}
                                </a>
                            </dd>
                        </div>
                    )}
                </dl>
            </div>

            {/* Client Info */}

            <div className="px-4 py-5 sm:px-6 flex flex-col items-center">
                <h3 className="text-sm text-gray-100 font-normal font-sans">Client</h3>
                <img
                    className="mt-3 h-16 w-16 rounded-full"
                    src={conversation.user.picture ?? undefined}
                    alt=""
                />
                <div className="flex items-center mt-3">
                    <p className="text-base text-white">{conversation.user.name}</p>
                    <Link href={`/users/${conversation.userId}`} className="ml-2">
                        <Button variant="icon">
                            <RiShareBoxFill className="w-4 h-4" />
                        </Button>
                    </Link>
                    <Button variant="icon" onClick={() => setIsEditing(true)}>
                        <RiEditLine className="w-4 h-4" />
                    </Button>
                </div>
                {conversation.user.dob && (
                    <p className="mt-1 text-sm text-gray-100">
                        Age {DateUtil.dobToAge(conversation.user.dob)}
                    </p>
                )}
            </div>

            {/* Goals */}
            <div className="px-4 py-5 sm:px-6">
                <h3 className="text-sm text-gray-100 font-normal font-sans">Goals</h3>
                <div className="mt-3 text-base text-white">
                    {conversation.user.goals?.length ? (
                        <ul className="space-y-1">
                            {conversation.user.goals?.map((goal, idx) => {
                                const goalInfo = goals[goal]
                                const [Icon, description] = goalInfo ? goalInfo : [null, goal]

                                return (
                                    <li key={idx} className="flex items-center space-x-3">
                                        {Icon && <Icon size={20} className="text-gray-100" />}
                                        <span className="text-base text-white">{description}</span>
                                    </li>
                                )
                            })}
                        </ul>
                    ) : (
                        <p>N/A</p>
                    )}
                </div>
            </div>

            {/* Notes */}
            <div className="px-4 py-5 sm:px-6">
                <h3 className="text-sm text-gray-100 font-normal font-sans">Notes</h3>
                <div className="mt-2 text-base text-white">
                    <p>{conversation.user.userNotes || 'N/A'}</p>
                </div>
            </div>

            {/* Risk profile */}
            <div className="px-4 py-5 sm:px-6">
                <h3 className="text-sm text-gray-100 font-normal font-sans">Risk profile</h3>
                <div className="mt-2 text-base text-white">
                    {riskProfile ? (
                        <div className="h-20">
                            <RiskSlider score={riskProfile.score} />
                        </div>
                    ) : (
                        'N/A'
                    )}
                </div>
            </div>

            {/* Insights */}
            <div className="px-4 py-5 sm:px-6">
                <dl className="grid grid-cols-2 gap-4">
                    <div className="col-span-2">
                        <dt className="text-sm text-gray-100 font-normal font-sans">Net Worth</dt>
                        <dd className="mt-1 text-base text-white flex items-center space-x-3">
                            <span>
                                {NumberUtil.format(insights.netWorthToday, 'short-currency')}
                            </span>
                            <TrendBadge trend={insights.netWorth.yearly} />
                        </dd>
                    </div>
                    <div>
                        <dt className="text-sm text-gray-100 font-normal font-sans">Assets</dt>
                        <dd className="mt-1 text-base text-white">
                            {NumberUtil.format(insights.debtAsset.asset, 'short-currency')}
                        </dd>
                    </div>
                    <div>
                        <dt className="text-sm text-gray-100 font-normal font-sans">Liabilities</dt>
                        <dd className="mt-1 text-base text-white">
                            {NumberUtil.format(insights.debtAsset.debt, 'short-currency')}
                        </dd>
                    </div>
                    <div>
                        <dt className="text-sm text-gray-100 font-normal font-sans">
                            Debt-to-Asset
                        </dt>
                        <dd className="mt-1 text-base text-white">
                            {NumberUtil.format(insights.debtAsset.ratio, 'percent', {
                                signDisplay: 'auto',
                            })}
                        </dd>
                    </div>
                    <div>
                        <dt className="text-sm text-gray-100 font-normal font-sans">
                            Debt-to-Income
                        </dt>
                        <dd className="mt-1 text-base text-white">
                            {NumberUtil.format(insights.debtIncome.ratio, 'percent', {
                                signDisplay: 'auto',
                            })}
                        </dd>
                    </div>
                    <div>
                        <dt className="text-sm text-gray-100 font-normal font-sans">
                            Income (Monthly)
                        </dt>
                        <dd className="mt-1 text-base text-white">
                            {NumberUtil.format(
                                insights.transactionSummary.income,
                                'short-currency'
                            )}
                        </dd>
                    </div>
                    <div>
                        <dt className="text-sm text-gray-100 font-normal font-sans">
                            Expenses (Monthly)
                        </dt>
                        <dd className="mt-1 text-base text-white">
                            {NumberUtil.format(
                                insights.transactionSummary.expenses,
                                'short-currency'
                            )}
                        </dd>
                    </div>
                    <div>
                        <dt className="text-sm text-gray-100 font-normal font-sans">Safety Net</dt>
                        <dd className="mt-1 text-base text-white">
                            {formatSafetyNet(insights.safetyNet)}
                        </dd>
                    </div>
                    <div>
                        <dt className="text-sm text-gray-100 font-normal font-sans">
                            Payments (Monthly)
                        </dt>
                        <dd className="mt-1 text-base text-white">
                            {NumberUtil.format(
                                insights.transactionSummary.payments,
                                'short-currency'
                            )}
                        </dd>
                    </div>
                </dl>

                <Tippy
                    render={(attrs) => (
                        <div
                            className="max-h-96 max-w-sm p-2 bg-gray-700 border rounded shadow overflow-scroll"
                            role="tooltip"
                            tabIndex={-1}
                            {...attrs}
                        >
                            <pre className="whitespace-pre-wrap text-sm text-gray-25 font-mono">
                                {JSON.stringify(insights, null, 2)}
                            </pre>
                        </div>
                    )}
                    trigger="click"
                    interactive
                >
                    <Button variant="secondary" className="mt-4">
                        View JSON
                    </Button>
                </Tippy>
            </div>

            {/* Asset / Debt breakdown */}
            <div className="px-4 py-4 sm:px-6">
                <Tab.Group>
                    <Tab.List className="w-full">
                        <Tab>Assets</Tab>
                        <Tab>Debts</Tab>
                        <Tab>Holdings</Tab>
                    </Tab.List>
                    <Tab.Panels className="mt-2">
                        {[
                            insights.accountSummary.filter((r) => r.classification === 'asset'),
                            insights.accountSummary.filter((r) => r.classification === 'liability'),
                        ].map((rows, idx) => (
                            <Tab.Panel key={idx}>
                                <table className="min-w-full divide-y divide-gray-300">
                                    <thead>
                                        <tr>
                                            <th
                                                scope="col"
                                                className="pr-2 py-2 text-left text-sm font-medium text-gray-100"
                                            >
                                                Type
                                            </th>
                                            <th
                                                scope="col"
                                                className="px-2 py-2 text-left text-sm font-medium text-gray-100"
                                            >
                                                Allocation
                                            </th>
                                            <th
                                                scope="col"
                                                className="px-2 py-2 text-left text-sm font-medium text-gray-100"
                                            >
                                                Amount
                                            </th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {orderBy(rows, (row) => row.allocation, 'desc').map(
                                            (row) => (
                                                <tr key={row.category}>
                                                    <td className="pr-2 py-1 text-base text-white">
                                                        {
                                                            AccountUtil.CATEGORIES[row.category]
                                                                .plural
                                                        }
                                                    </td>
                                                    <td className="px-2 py-1 text-base text-white">
                                                        {NumberUtil.format(
                                                            row.allocation,
                                                            'percent',
                                                            {
                                                                signDisplay: 'never',
                                                            }
                                                        )}
                                                    </td>
                                                    <td className="px-2 py-1 text-base text-white">
                                                        {NumberUtil.format(
                                                            row.balance,
                                                            'short-currency',
                                                            { signDisplay: 'never' }
                                                        )}
                                                    </td>
                                                </tr>
                                            )
                                        )}
                                    </tbody>
                                </table>
                            </Tab.Panel>
                        ))}
                        <Tab.Panel>
                            <div className="overflow-x-auto">
                                <table className="min-w-full divide-y divide-gray-300">
                                    <thead>
                                        <th
                                            scope="col"
                                            className="pr-2 py-2 text-left text-sm font-medium text-gray-100"
                                        >
                                            Type
                                        </th>
                                        <th
                                            scope="col"
                                            className="px-2 py-2 text-left text-sm font-medium text-gray-100"
                                        >
                                            Allocation
                                        </th>
                                        <th
                                            scope="col"
                                            className="px-2 py-2 text-left text-sm font-medium text-gray-100"
                                        >
                                            Amount
                                        </th>
                                    </thead>
                                    <tbody>
                                        {insights.holdingBreakdown.map(
                                            ({ category, allocation, value, holdings }) => (
                                                <Fragment key={category}>
                                                    <tr className="text-base text-white font-medium">
                                                        <td className="pr-2 py-1">{category}</td>
                                                        <td className="px-2 py-1">
                                                            {NumberUtil.format(
                                                                allocation,
                                                                'percent',
                                                                { signDisplay: 'never' }
                                                            )}
                                                        </td>
                                                        <td className="px-2 py-1">
                                                            {NumberUtil.format(
                                                                value,
                                                                'short-currency',
                                                                { signDisplay: 'never' }
                                                            )}
                                                        </td>
                                                    </tr>
                                                    {holdings.map(
                                                        ({ security, allocation, value }) => (
                                                            <tr
                                                                key={security.id}
                                                                className="text-base text-gray-50"
                                                            >
                                                                <td className="px-2 py-0.5">
                                                                    {security.symbol ||
                                                                        security.name}
                                                                </td>
                                                                <td className="px-2 py-0.5">
                                                                    {NumberUtil.format(
                                                                        allocation,
                                                                        'percent',
                                                                        { signDisplay: 'never' }
                                                                    )}
                                                                </td>
                                                                <td className="px-2 py-0.5">
                                                                    {NumberUtil.format(
                                                                        value,
                                                                        'short-currency',
                                                                        { signDisplay: 'never' }
                                                                    )}
                                                                </td>
                                                            </tr>
                                                        )
                                                    )}
                                                </Fragment>
                                            )
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </Tab.Panel>
                    </Tab.Panels>
                </Tab.Group>
            </div>
        </div>
    )
}

function formatSafetyNet({ months }: Props['conversation']['user']['insights']['safetyNet']) {
    return months.lt(24)
        ? `${months.toFixed(0)} months`
        : months.lte(120)
        ? `${months.divToInt(12).toFixed(0)} years`
        : '>10 years'
}
