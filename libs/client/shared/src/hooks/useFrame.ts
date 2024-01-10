import { useEffect, useRef } from 'react'

export function useFrame(callback: (time: DOMHighResTimeStamp, deltaTime: number) => void) {
    const frameRequest = useRef<number>()
    const previousTimeRef = useRef<DOMHighResTimeStamp>()

    const animate = (time: DOMHighResTimeStamp) => {
        if (previousTimeRef.current !== undefined) {
            const deltaTime = time - previousTimeRef.current
            callback(time, deltaTime)
        }
        previousTimeRef.current = time
        frameRequest.current = requestAnimationFrame(animate)
    }

    useEffect(() => {
        frameRequest.current = requestAnimationFrame(animate)
        return () => {
            if (frameRequest.current !== undefined) cancelAnimationFrame(frameRequest.current)
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [])
}
