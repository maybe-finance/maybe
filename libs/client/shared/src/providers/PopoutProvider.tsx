import type { PropsWithChildren, ReactNode } from 'react'
import { createContext, useContext, useState } from 'react'

export interface PopoutContext {
    popoutContents: ReactNode | null
    open(component: ReactNode | null): void
    close(): void
}

export const PopoutContext = createContext<PopoutContext | undefined>(undefined)

export function usePopoutContext() {
    const context = useContext(PopoutContext)

    if (!context) throw new Error('usePopoutContext() must be used within <PopoutProvider />')

    return context
}

export function PopoutProvider({ children }: PropsWithChildren<{}>) {
    const [popoutContents, setPopoutContents] = useState<ReactNode | null>(null)

    return (
        <PopoutContext.Provider
            value={{
                popoutContents,
                open: setPopoutContents,
                close: () => setPopoutContents(null),
            }}
        >
            {children}
        </PopoutContext.Provider>
    )
}
