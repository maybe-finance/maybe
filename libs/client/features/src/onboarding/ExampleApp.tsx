import { useAccountApi } from '@maybe-finance/client/shared'
import {
    AccordionRow,
    type AccordionRowProps,
    LoadingPlaceholder,
    TrendLine,
} from '@maybe-finance/design-system'
import { NumberUtil, type SharedType } from '@maybe-finance/shared'
import classNames from 'classnames'
import { DateTime } from 'luxon'
import {
    RiArrowLeftLine,
    RiCheckLine,
    RiFlagLine,
    RiFolderOpenLine,
    RiPieChart2Line,
} from 'react-icons/ri'
import type DecimalJS from 'decimal.js'

const now = DateTime.now()

export function ExampleApp({ checklist }: { checklist?: string[] }) {
    const { useAccountRollup } = useAccountApi()

    const { data } = useAccountRollup({
        start: now.minus({ months: 1 }).toISO(),
        end: now.toISO(),
    })

    return (
        <div
            className="flex flex-col min-h-[700px] p-4 rounded-[32px] border border-gray-600 border-opacity-60 backdrop-blur-xl"
            style={{
                background:
                    'linear-gradient(180deg, rgba(35, 36, 40, 0.2) 0%, rgba(68, 71, 76, 0.2) 100%)',
            }}
        >
            <div className="grow flex rounded-[20px] border border-gray-600 border-opacity-60 overflow-hidden">
                <div className="flex bg-white bg-opacity-[0.02]">
                    <div className="flex flex-col items-center w-[88px] pt-8 pb-6 border-r border-gray-700">
                        <img
                            src="/assets/maybe.svg"
                            alt="Maybe Finance Logo"
                            className="mb-6"
                            height={36}
                            width={36}
                        />
                        <div className="flex flex-col items-center gap-5 mt-4">
                            {Object.entries({
                                'Net worth': RiPieChart2Line,
                                Accounts: RiFolderOpenLine,
                                Planning: RiFlagLine,
                            }).map(([label, Icon], idx) => (
                                <div
                                    key={idx}
                                    className={classNames(
                                        'relative flex flex-col items-center w-[88px] h-12 px-1 rounded-lg text-gray-100',
                                        idx === 0 && 'text-gray-50'
                                    )}
                                >
                                    {idx === 0 && (
                                        <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-5 bg-white rounded-r-lg"></div>
                                    )}
                                    <Icon
                                        className={classNames(
                                            'shrink-0 w-6 h-6',
                                            idx === 0 && 'text-gray-25'
                                        )}
                                    />
                                    <span className="shrink-0 mt-1.5 text-sm font-medium text-center">
                                        {label}
                                    </span>
                                </div>
                            ))}
                        </div>
                    </div>
                    <div className="px-4 pt-8 w-[330px]">
                        {checklist ? (
                            <>
                                <div className="flex space-x-1.5">
                                    <RiArrowLeftLine className="w-4 h-4 text-gray-50" />
                                    <span className="grow text-sm text-white">Getting started</span>
                                </div>
                                <div className="mt-4 text-sm text-cyan">
                                    1 of {checklist.length + 1} done
                                </div>
                                <div className="mt-2.5 w-full h-1.5 bg-gray-700 rounded-sm">
                                    <div
                                        className="h-full bg-cyan rounded-sm transition-all"
                                        style={{ width: `${100 / (checklist.length + 1)}%` }}
                                    ></div>
                                </div>
                                <ul className="mt-6 space-y-6">
                                    {['bank account', ...checklist].map((name, idx) => (
                                        <li key={idx} className="flex items-center space-x-2.5">
                                            <div
                                                className={classNames(
                                                    'flex items-center justify-center w-6 h-6 text-sm rounded-full transition-colors',
                                                    idx === 0
                                                        ? 'text-cyan bg-cyan bg-opacity-10'
                                                        : 'text-white bg-gray-600'
                                                )}
                                            >
                                                {idx === 0 ? (
                                                    <RiCheckLine className="w-4 h-4" />
                                                ) : (
                                                    idx + 1
                                                )}
                                            </div>
                                            <span
                                                className={classNames(
                                                    'text-sm',
                                                    idx === 0
                                                        ? 'text-gray-100 line-through'
                                                        : 'text-white'
                                                )}
                                            >
                                                {[
                                                    'cash',
                                                    'crypto',
                                                    'vehicle',
                                                    'property',
                                                    'valuables',
                                                ].includes(name)
                                                    ? 'Manually add'
                                                    : 'Connect'}{' '}
                                                {name}
                                            </span>
                                        </li>
                                    ))}
                                </ul>
                            </>
                        ) : (
                            <>
                                <h5 className="uppercase">Assets &amp; Debts</h5>
                                <div className="mt-8">
                                    {data?.map(
                                        ({ key: classification, title, balances, items }) => (
                                            <AccountsSidebarRow
                                                key={classification}
                                                label={title}
                                                balances={balances.data}
                                                inverted={classification === 'liability'}
                                                syncing={items.some(({ items }) =>
                                                    items.some((a) => a.syncing)
                                                )}
                                            >
                                                {items.map(
                                                    ({ key: category, title, balances, items }) => (
                                                        <AccountsSidebarRow
                                                            key={category}
                                                            label={title}
                                                            balances={balances.data}
                                                            inverted={
                                                                classification === 'liability'
                                                            }
                                                            level={1}
                                                            syncing={items.some((a) => a.syncing)}
                                                        >
                                                            {items.map(
                                                                ({
                                                                    id,
                                                                    name,
                                                                    mask,
                                                                    connection,
                                                                    balances,
                                                                    syncing,
                                                                }) => (
                                                                    <AccountsSidebarRow
                                                                        key={id}
                                                                        label={name}
                                                                        institutionName={
                                                                            connection?.name
                                                                        }
                                                                        accountMask={mask}
                                                                        balances={balances.data}
                                                                        inverted={
                                                                            classification ===
                                                                            'liability'
                                                                        }
                                                                        level={2}
                                                                        syncing={syncing}
                                                                    />
                                                                )
                                                            )}
                                                        </AccountsSidebarRow>
                                                    )
                                                )}
                                            </AccountsSidebarRow>
                                        )
                                    ) ?? <div></div>}
                                </div>
                            </>
                        )}
                    </div>
                </div>
                <div className="w-[800px]"></div>
            </div>
        </div>
    )
}

function AccountsSidebarRow({
    label,
    level = 0,
    balances,
    institutionName,
    accountMask,
    inverted = false,
    syncing = false,
    ...rest
}: AccordionRowProps & {
    label: string
    balances: { date: string; balance: SharedType.Decimal }[]
    institutionName?: string | null
    accountMask?: string | null
    inverted?: boolean
    syncing?: boolean
}) {
    const startBalance = balances[0].balance
    const endBalance = balances[balances.length - 1].balance

    const percentChange = NumberUtil.calculatePercentChange(startBalance, endBalance)

    let isPositive = balances.length > 1 && (endBalance as DecimalJS).gt(startBalance as DecimalJS)
    if (inverted) isPositive = !isPositive

    const overlayClassName = ['!bg-gray-600', '!bg-gray-600', '!bg-gray-700'][level]

    // Hide flat lines or inifite
    const hasValidValue = !percentChange.isZero() && percentChange.isFinite()

    return (
        <AccordionRow
            {...rest}
            collapsible={level < 2}
            expanded={true}
            level={level}
            className={classNames(
                'pointer-events-none',
                ['!bg-gray-500 !bg-opacity-50', '!bg-gray-500 !bg-opacity-50', '!bg-transparent'][
                    level
                ]
            )}
            data-testid="account-accordion-row"
            label={
                <div
                    className="flex items-center space-x-1"
                    data-testid="account-accordion-row-name"
                >
                    <div className="flex-1 min-w-0">
                        <p className="text-base font-normal line-clamp-2">{label}</p>

                        {(institutionName || accountMask) && (
                            <div className="mt-0.5 flex flex-wrap items-center space-x-1 text-sm text-gray-100">
                                {institutionName && (
                                    <span className="line-clamp-2">{institutionName}</span>
                                )}
                                {accountMask && (
                                    <span className="shrink-0">
                                        &nbsp;&#183;&#183;&#183;&#183; {accountMask}
                                    </span>
                                )}
                            </div>
                        )}
                    </div>

                    {balances.length && (
                        <div className="shrink-0 flex flex-col justify-center items-end font-semibold tabular-nums h-9">
                            <LoadingPlaceholder
                                isLoading={syncing}
                                overlayClassName={overlayClassName}
                            >
                                <div data-testid="account-accordion-row-balance" className="pb-1">
                                    {syncing
                                        ? '$X,XXX,XXX'
                                        : NumberUtil.format(endBalance, 'currency', {
                                              minimumFractionDigits: 0,
                                              maximumFractionDigits: 0,
                                          })}
                                </div>
                            </LoadingPlaceholder>
                            {(balances.length > 1 || syncing) && hasValidValue && (
                                <div className="mt-1">
                                    <LoadingPlaceholder
                                        isLoading={syncing}
                                        overlayClassName={overlayClassName}
                                        className="!inline-flex"
                                    >
                                        {!syncing && (
                                            <div className="inline-block w-8 h-3">
                                                <TrendLine
                                                    inverted={inverted}
                                                    data={balances.map(({ date, balance }) => ({
                                                        key: date,
                                                        value: balance.toNumber(),
                                                    }))}
                                                />
                                            </div>
                                        )}
                                        <span
                                            className={classNames(
                                                'ml-1',
                                                percentChange.isZero()
                                                    ? 'text-gray-200'
                                                    : isPositive
                                                    ? 'text-teal'
                                                    : 'text-red'
                                            )}
                                        >
                                            {syncing
                                                ? '+XXX%'
                                                : NumberUtil.format(percentChange, 'percent')}
                                        </span>
                                    </LoadingPlaceholder>
                                </div>
                            )}
                        </div>
                    )}
                </div>
            }
        />
    )
}
