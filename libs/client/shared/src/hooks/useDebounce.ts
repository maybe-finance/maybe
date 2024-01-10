import { useEffect, useState } from 'react'

/**
 * Returns a value updated to match the provided value after it hasn't changed for the specified delay
 */
export function useDebounce<T>(value: T, delayMilliseconds: number) {
    const [debouncedValue, setDebouncedValue] = useState(value)

    useEffect(() => {
        const timeout = setTimeout(() => {
            setDebouncedValue(value)
        }, delayMilliseconds)

        return () => clearTimeout(timeout)
    }, [value, delayMilliseconds])

    return debouncedValue
}
