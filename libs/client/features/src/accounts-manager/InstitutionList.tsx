import type { SharedType } from '@maybe-finance/shared'
import { useMemo } from 'react'
import { InfiniteScroll, useInstitutionApi } from '@maybe-finance/client/shared'
import { Button, LoadingSpinner } from '@maybe-finance/design-system'

export const MIN_QUERY_LENGTH = 2

export default function InstitutionList({
    searchQuery = '',
    onClick,
    onAddManualAccountClick,
}: {
    searchQuery?: string
    onClick(institution: SharedType.Institution): void
    onAddManualAccountClick(): void
}) {
    const { useInstitutions } = useInstitutionApi()

    const institutionsQuery = useInstitutions(
        { search: searchQuery },
        { enabled: searchQuery.length >= MIN_QUERY_LENGTH }
    )

    const institutions = useMemo<SharedType.Institution[]>(() => {
        if (!institutionsQuery.data?.pages) return []

        // Flatten pages
        return institutionsQuery.data.pages.reduce(
            (institutions, page) => [...institutions, ...page.institutions],
            [] as SharedType.Institution[]
        )
    }, [institutionsQuery.data])

    return (
        <div className="h-80 -ml-3 -mr-6 pr-4 custom-gray-scroll">
            <InfiniteScroll
                useWindow={false}
                initialLoad={false}
                loadMore={() => institutionsQuery.fetchNextPage()}
                hasMore={institutionsQuery.hasNextPage}
            >
                <div>
                    {institutionsQuery?.data && (
                        <ul className="space-y-2 text-base">
                            {institutions.map((institution) => (
                                <li
                                    key={institution.id}
                                    className="flex items-center p-3 rounded-lg bg-transparent hover:bg-gray-600 overflow-x-hidden"
                                    role="button"
                                    onClick={() => onClick(institution)}
                                >
                                    <div className="shrink-0 mr-4">
                                        <div className="relative w-10 h-10 overflow-hidden rounded-full">
                                            {institution.logoUrl || institution.logo ? (
                                                <img
                                                    className="absolute w-full h-full"
                                                    src={
                                                        institution.logoUrl ??
                                                        `data:image/jpeg;base64, ${institution.logo}`
                                                    }
                                                    loading="lazy"
                                                    alt={`${institution.name} Logo`}
                                                />
                                            ) : (
                                                <div
                                                    className="w-full h-full bg-gray-400"
                                                    style={
                                                        institution.primaryColor
                                                            ? {
                                                                  backgroundColor:
                                                                      institution.primaryColor,
                                                              }
                                                            : undefined
                                                    }
                                                ></div>
                                            )}
                                        </div>
                                    </div>
                                    <div className="grow min-w-0">
                                        <span className="block leading-6 text-white overflow-x-hidden text-ellipsis">
                                            {institution.name}
                                        </span>
                                        {institution.url && (
                                            <span className="block text-sm leading-4 text-gray-100 overflow-x-hidden text-ellipsis">
                                                {institution.url.replace(
                                                    /^(https?:\/\/)?(www\.)?/,
                                                    ''
                                                )}
                                            </span>
                                        )}
                                    </div>
                                </li>
                            ))}
                        </ul>
                    )}

                    {(institutionsQuery.isLoading || institutionsQuery.isFetchingNextPage) && (
                        <div className="flex items-center justify-center py-4">
                            <LoadingSpinner variant="secondary" />
                        </div>
                    )}
                </div>
            </InfiniteScroll>
            {institutionsQuery?.data && !institutionsQuery.isLoading && !institutions.length && (
                <div className="flex flex-col items-center justify-center w-full h-full px-1">
                    <span className="block text-lg text-white font-display font-bold">
                        No institutions found
                    </span>
                    <p className="mt-2 text-center text-base text-gray-50">
                        There were no institutions matching "{searchQuery}". Try another search
                        term, or add it as a manual account.
                    </p>
                    <Button className="mt-4" variant="secondary" onClick={onAddManualAccountClick}>
                        Add manual account
                    </Button>
                </div>
            )}
        </div>
    )
}
