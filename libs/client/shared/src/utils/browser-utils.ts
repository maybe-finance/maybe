import type {
    PlaidLinkError,
    PlaidLinkOnEventMetadata,
    PlaidLinkOnExitMetadata,
} from 'react-plaid-link'

export async function copyToClipboard(text: string) {
    if ('clipboard' in navigator) {
        return navigator.clipboard.writeText(text)
    } else {
        return document.execCommand('copy', true, text)
    }
}

export function getLocalStorageSession<TData>(key: string, initialValue: TData) {
    return {
        getLocalStorageItem: () => {
            if (typeof window === 'undefined') return initialValue

            const item = window.localStorage.getItem(key)

            return item ? (JSON.parse(item) as TData) : initialValue
        },
        setLocalStorageItem: (data: TData | ((data: TData) => TData)) => {
            if (typeof window === 'undefined') return

            const previousValue = window.localStorage.getItem(key)

            const isFunc = data instanceof Function

            window.localStorage.setItem(
                key,
                JSON.stringify(
                    isFunc ? data(previousValue ? JSON.parse(previousValue) : initialValue) : data
                )
            )
        },
    }
}

export function prepareSentryContext(
    plaidMetadata: PlaidLinkOnExitMetadata | PlaidLinkOnEventMetadata,
    plaidError?: PlaidLinkError | null
): { [key: string]: any } | undefined {
    if (!plaidError && !plaidMetadata) return undefined

    // The keys here will be the headers in Sentry context sections (hence the formatted spacing)
    const errorContext = plaidError ? { 'Plaid Error': plaidError } : undefined
    const metadataContext = plaidMetadata ? { 'Plaid Metadata': plaidMetadata } : undefined

    return {
        ...errorContext,
        ...metadataContext,
    }
}
