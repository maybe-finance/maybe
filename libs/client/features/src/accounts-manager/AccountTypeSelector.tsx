import { useState, useRef, useEffect } from 'react'
import { RiFolderLine, RiHandCoinLine, RiLockLine, RiSearchLine } from 'react-icons/ri'
import maxBy from 'lodash/maxBy'
import {
    BoxIcon,
    useAccountContext,
    useDebounce,
    usePlaid,
    useTellerConfig,
    useTellerConnect,
} from '@maybe-finance/client/shared'
import { Input } from '@maybe-finance/design-system'
import InstitutionGrid from './InstitutionGrid'
import { AccountTypeGrid } from './AccountTypeGrid'
import InstitutionList, { MIN_QUERY_LENGTH } from './InstitutionList'
import { useLogger } from '@maybe-finance/client/shared'

const SEARCH_DEBOUNCE_MS = 300

export default function AccountTypeSelector({
    view,
    onViewChange,
}: {
    view: string
    onViewChange: (view: string) => void
}) {
    const logger = useLogger()
    const { setAccountManager } = useAccountContext()

    const [searchQuery, setSearchQuery] = useState<string>('')
    const debouncedSearchQuery = useDebounce(searchQuery, SEARCH_DEBOUNCE_MS)

    const showInstitutionList =
        searchQuery.length >= MIN_QUERY_LENGTH &&
        debouncedSearchQuery.length >= MIN_QUERY_LENGTH &&
        view !== 'manual'

    const config = useTellerConfig(logger)

    const { openPlaid } = usePlaid()
    const { open: openTeller } = useTellerConnect(config, logger)

    const inputRef = useRef<HTMLInputElement>(null)

    useEffect(() => {
        if (inputRef.current) {
            inputRef.current.focus()
        }
    }, [])

    return (
        <div>
            {/* Search */}
            {view !== 'manual' && view !== 'crypto' && (
                <Input
                    className="mb-4"
                    type="text"
                    placeholder="Search for an institution"
                    fixedLeftOverride={<RiSearchLine className="w-5 h-5" />}
                    inputClassName="pl-10"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    ref={inputRef}
                />
            )}

            {showInstitutionList && (
                <InstitutionList
                    searchQuery={debouncedSearchQuery}
                    onClick={({ providers }) => {
                        const providerInstitution = maxBy(providers, (p) => p.rank)
                        if (!providerInstitution) {
                            alert('No provider found for institution')
                            return
                        }

                        switch (providerInstitution.provider) {
                            case 'PLAID':
                                openPlaid(providerInstitution.providerId)
                                break
                            case 'TELLER':
                                openTeller(providerInstitution.providerId)
                                break
                            default:
                                break
                        }
                    }}
                    onAddManualAccountClick={() => onViewChange('manual')}
                />
            )}

            {view === 'default' && !showInstitutionList && (
                <div>
                    <AccountTypeGrid
                        onChange={(view) => {
                            // Some actions go directly to a form while others go to a second modal view for refinement of criteria
                            switch (view) {
                                case 'property-form':
                                    setAccountManager({ view: 'add-property', defaultValues: {} })
                                    break
                                case 'vehicle-form':
                                    setAccountManager({ view: 'add-vehicle', defaultValues: {} })
                                    break
                                default:
                                    // Go to a view below
                                    onViewChange(view)
                            }
                        }}
                    />
                    <div className="flex mt-6 space-x-3 text-gray-100">
                        <span>
                            <RiLockLine className="w-5 h-5" />
                        </span>
                        <p className="mb-2 text-sm">
                            Adding your accounts is a big step. That&#39;s why we take this
                            seriously. No one can access your accounts but you. Your information is
                            always protected and secure.
                        </p>
                    </div>
                </div>
            )}

            {(view === 'banks' || view === 'brokerages' || view === 'crypto') &&
                !showInstitutionList && (
                    <div className="flex flex-col">
                        {view === 'crypto' && (
                            <p className="mb-4 text-sm text-gray-100">
                                At the moment we don't have integrations for crypto exchanges or
                                assets, so for the time being you'll need to enter your portfolio
                                manually.
                            </p>
                        )}
                        <InstitutionGrid
                            type={view}
                            onClick={(data, cryptoExchangeName) => {
                                // Crypto exchanges not supported yet, go directly to add asset form
                                if (view === 'crypto') {
                                    setAccountManager({
                                        view: 'add-asset',
                                        defaultValues: {
                                            name: cryptoExchangeName,
                                            categoryUser: 'crypto',
                                        },
                                    })
                                    return
                                }

                                if (!data) {
                                    return
                                }

                                switch (data.provider) {
                                    case 'PLAID':
                                        openPlaid(data.providerId)
                                        break
                                    case 'TELLER':
                                        openTeller(data.providerId)
                                        break
                                    default:
                                        break
                                }
                            }}
                        />
                    </div>
                )}

            {(view === 'banks' ||
                view === 'brokerages' ||
                view === 'crypto' ||
                showInstitutionList) && (
                <p className="mt-4 text-base text-center">
                    Can't find your institution?{' '}
                    <span
                        className="underline cursor-pointer text-cyan hover:opacity-80"
                        onClick={() => {
                            switch (view) {
                                case 'banks':
                                    setAccountManager({
                                        view: 'add-asset',
                                        defaultValues: { categoryUser: 'cash', name: 'Cash' },
                                    })
                                    break
                                case 'brokerages':
                                    setAccountManager({
                                        view: 'add-asset',
                                        defaultValues: {
                                            categoryUser: 'investment',
                                            name: 'Investment',
                                        },
                                    })
                                    break
                                case 'crypto':
                                    setAccountManager({
                                        view: 'add-asset',
                                        defaultValues: {
                                            categoryUser: 'crypto',
                                            name: 'Cryptocurrency',
                                        },
                                    })
                                    break
                                default:
                                    onViewChange('manual')
                            }
                        }}
                    >
                        Add it manually
                    </span>
                </p>
            )}

            {view === 'manual' && (
                <div className="grid grid-cols-2 gap-4">
                    <div
                        className="flex flex-col items-center justify-between p-4 bg-gray-500 cursor-pointer rounded-xl hover:bg-gray-400"
                        onClick={() =>
                            setAccountManager({
                                view: 'add-asset',
                                defaultValues: { name: debouncedSearchQuery },
                            })
                        }
                        data-testid="manual-add-asset"
                    >
                        <BoxIcon variant="teal" icon={RiFolderLine} />
                        <p className="mt-4 text-base">Manual Asset</p>
                    </div>
                    <div
                        className="flex flex-col items-center justify-between p-4 bg-gray-500 cursor-pointer rounded-xl hover:bg-gray-400 "
                        onClick={() =>
                            setAccountManager({
                                view: 'add-liability',
                                defaultValues: { name: debouncedSearchQuery },
                            })
                        }
                        data-testid="manual-add-debt"
                    >
                        <BoxIcon variant="red" icon={RiHandCoinLine} />
                        <p className="mt-4 text-base">Manual Debt</p>
                    </div>
                </div>
            )}
        </div>
    )
}
