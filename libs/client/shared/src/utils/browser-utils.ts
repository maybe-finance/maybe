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
