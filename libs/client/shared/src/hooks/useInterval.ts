import { useEffect, useLayoutEffect, useRef } from 'react'

export function useInterval(callback: () => any, delay?: number | false | null) {
    const savedCallback = useRef(callback)

    // remember the latest callback if it changes.
    useLayoutEffect(() => {
        savedCallback.current = callback
    }, [callback])

    useEffect(() => {
        // don't schedule if no delay is specified
        if (!delay) return

        const id = setInterval(() => savedCallback.current(), delay)
        return () => clearInterval(id)
    }, [delay])
}
