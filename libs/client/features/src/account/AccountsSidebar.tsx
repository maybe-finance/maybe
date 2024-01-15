import type { AccordionRowProps } from '@maybe-finance/design-system'
import type { SharedType } from '@maybe-finance/shared'
import { useCallback, useMemo } from 'react'
import {
    RiAlertLine,
    RiCloseFill,
    RiInformationLine as InfoIcon,
    RiInformationLine,
} from 'react-icons/ri'
import { AnimatePresence, motion } from 'framer-motion'
import { AccordionRow, LoadingPlaceholder, TrendLine } from '@maybe-finance/design-system'
import classNames from 'classnames'
import type DecimalJS from 'decimal.js'
import { AiOutlineExclamationCircle } from 'react-icons/ai'
import {
    useAccountApi,
    useQueryParam,
    useUserAccountContext,
    useProviderStatus,
    useAccountContext,
    useLocalStorage,
} from '@maybe-finance/client/shared'
import { NumberUtil } from '@maybe-finance/shared'

function SidebarAccountsLoader() {
    return (
        <div className="">
            {Array(6)
                .fill(0)
                .map((_, idx) => {
                    return (
                        <div key={idx} className="flex h-14 mb-1 rounded bg-gray overflow-hidden">
                            <LoadingPlaceholder isLoading={true} className="grow" />
                        </div>
                    )
                })}
        </div>
    )
}

export default function AccountsSidebar() {
    const { useAccountRollup } = useAccountApi()
    const activeAccountId = useQueryParam('accountId', 'number')

    const providerStatus = useProviderStatus()

    const { someConnectionsSyncing, someAccountsSyncing, connectionsSyncing, syncProgress } =
        useUserAccountContext()

    const { dateRange } = useAccountContext()

    const connectionsStatus = useMemo(
        () => ({
            syncing: someAccountsSyncing || someConnectionsSyncing,
            pending:
                connectionsSyncing.filter((connection) => connection.syncStatus === 'PENDING')
                    .length > 0,
        }),
        [someAccountsSyncing, someConnectionsSyncing, connectionsSyncing]
    )

    const { error, data } = useAccountRollup(dateRange)

    const isLoading = useMemo(() => {
        if (error) {
            return false
        }

        if (!connectionsStatus.syncing && data) {
            return false
        }

        // If any connection is syncing and there are > 1 accounts, show the accounts
        if (connectionsStatus.syncing && data && data.length > 0) {
            return false
        }

        return true
    }, [data, error, connectionsStatus])

    const [toggleState, setToggleState] = useLocalStorage<{ [key: string]: boolean }>(
        'ACCOUNTS_LIST_TOGGLE_STATE',
        {}
    )

    const updateToggleState = useCallback(
        (key: string, isExpanded: boolean) => {
            setToggleState({
                ...toggleState,
                [key]: isExpanded,
            })
        },
        [toggleState, setToggleState]
    )

    if (error) {
        return (
            <div className="flex items-center justify-center text-red h-20">
                <AiOutlineExclamationCircle className="w-5 h-5 mr-2" />
                <p>Unable to load accounts</p>
            </div>
        )
    }

    if (!isLoading && (!data || !data.length)) {
        return (
            <div className="flex items-center justify-center h-20">
                <InfoIcon className="w-5 h-5 mr-2" />
                <p>No accounts found</p>
            </div>
        )
    }

    return (
        <div>
            <AnimatePresence>
                {syncProgress && (
                    <motion.div
                        className="overflow-hidden text-center text-base text-gray-100"
                        key="importing-message"
                        initial={{ height: 0 }}
                        animate={{ height: 'auto' }}
                        exit={{ height: 0 }}
                    >
                        {syncProgress.description}...
                        <div className="my-4">
                            <div className="relative w-full h-[3px] rounded-full overflow-hidden bg-gray-200">
                                {syncProgress.progress ? (
                                    <motion.div
                                        key="progress-determinate"
                                        initial={{ width: 0 }}
                                        animate={{ width: `${syncProgress.progress * 100}%` }}
                                        transition={{ ease: 'easeOut', duration: 0.5 }}
                                        className="h-full rounded-full bg-gray-100"
                                    ></motion.div>
                                ) : (
                                    <motion.div
                                        key="progress-indeterminate"
                                        className="w-[40%] h-full rounded-full bg-gray-100"
                                        animate={{ translateX: ['-100%', '250%'] }}
                                        transition={{ repeat: Infinity, duration: 1.8 }}
                                    ></motion.div>
                                )}
                            </div>
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
            {providerStatus.statusMessage && (
                <div className="flex gap-2 bg-yellow rounded bg-opacity-10 text-yellow-500 p-3 mb-4">
                    <span>
                        <RiAlertLine className="w-5 h-5" />
                    </span>
                    {providerStatus.isCollapsed ? (
                        <>
                            <p className="text-base">Data provider service disruption</p>
                            <span className="ml-auto" onClick={() => providerStatus.expand()}>
                                <RiInformationLine className="w-5 h-5 cursor-pointer hover:opacity-80" />
                            </span>
                        </>
                    ) : (
                        <>
                            <p className="text-base">{providerStatus.statusMessage}</p>
                            <span className="ml-auto" onClick={() => providerStatus.dismiss()}>
                                <RiCloseFill className="w-5 h-5 cursor-pointer hover:opacity-80" />
                            </span>
                        </>
                    )}
                </div>
            )}
            {isLoading || !data ? (
                <SidebarAccountsLoader />
            ) : (
                data.map(({ key: classification, title, balances, items }) => (
                    <AccountsSidebarRow
                        key={classification}
                        label={title}
                        balances={balances.data}
                        inverted={classification === 'liability'}
                        onToggle={(isExpanded) => updateToggleState(title, isExpanded)}
                        expanded={toggleState[title] !== false}
                        syncing={items.some(({ items }) => items.some((a) => a.syncing))}
                    >
                        {items.map(({ key: category, title, balances, items }) => (
                            <AccountsSidebarRow
                                key={category}
                                label={title}
                                balances={balances.data}
                                inverted={classification === 'liability'}
                                onToggle={(isExpanded) =>
                                    updateToggleState(`${title}-${classification}`, isExpanded)
                                }
                                expanded={toggleState[title] !== false}
                                level={1}
                                syncing={items.some((a) => a.syncing)}
                            >
                                {items.map(({ id, name, mask, connection, balances, syncing }) => (
                                    <AccountsSidebarRow
                                        key={id}
                                        label={name}
                                        institutionName={connection?.name}
                                        accountMask={mask}
                                        balances={balances.data}
                                        inverted={classification === 'liability'}
                                        level={2}
                                        collapsible={false}
                                        syncing={syncing}
                                        active={id === activeAccountId}
                                        url={`/accounts/${id}`}
                                    />
                                ))}
                            </AccountsSidebarRow>
                        ))}
                    </AccountsSidebarRow>
                ))
            )}
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
    active = false,
    url,
    ...rest
}: AccordionRowProps & {
    label: string
    balances: { date: string; balance: SharedType.Decimal }[]
    institutionName?: string | null
    accountMask?: string | null
    inverted?: boolean
    syncing?: boolean
    active?: boolean
    url?: string
}) {
    const startBalance = balances[0].balance
    const endBalance = balances[balances.length - 1].balance

    const percentChange = NumberUtil.calculatePercentChange(startBalance, endBalance)

    let isPositive = balances.length > 1 && (endBalance as DecimalJS).gt(startBalance as DecimalJS)
    if (inverted) isPositive = !isPositive

    const overlayClassName = ['!bg-gray-400', '!bg-gray-600', '!bg-gray-700'][level]

    // Hide flat lines or inifite
    const hasValidValue = !percentChange.isZero() && percentChange.isFinite()

    return (
        <AccordionRow
            {...rest}
            level={level}
            href={level === 2 && url ? url : undefined}
            active={active}
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
