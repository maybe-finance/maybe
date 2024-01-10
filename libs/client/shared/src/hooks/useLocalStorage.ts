import type { Dispatch, SetStateAction } from 'react'
import { useEffect, useState } from 'react'

export function useLocalStorage<T>(key: string, initialValue: T): [T, Dispatch<SetStateAction<T>>] {
    const [value, setValue] = useState<T>(() => {
        if (typeof window !== 'undefined') {
            try {
                const storedValue = localStorage.getItem(key)

                if (storedValue) {
                    return JSON.parse(storedValue)
                }
            } catch (e) {
                console.warn(`Failed to get ${key} from local storage`, e)
            }
        }

        return initialValue
    })

    useEffect(() => {
        if (typeof window !== 'undefined') {
            try {
                localStorage.setItem(key, JSON.stringify(value))
            } catch (e) {
                console.warn(`Failed to set ${key} in local storage`, e)
            }
        }
    }, [key, value])

    return [value, setValue]
}
