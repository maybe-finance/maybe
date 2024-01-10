import type { PropsWithChildren, RefObject } from 'react'
import { createContext, useContext } from 'react'

const LayoutContext = createContext<{ overlayContainer: RefObject<HTMLDivElement> | undefined }>({
    overlayContainer: undefined,
})

export function useLayoutContext() {
    return useContext(LayoutContext)
}

export function LayoutContextProvider({
    overlayContainer,
    children,
}: PropsWithChildren<{
    overlayContainer: RefObject<HTMLDivElement>
}>) {
    return <LayoutContext.Provider value={{ overlayContainer }}>{children}</LayoutContext.Provider>
}
