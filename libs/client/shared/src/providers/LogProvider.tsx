import type { PropsWithChildren } from 'react'
import { createContext } from 'react'

export type Logger = Pick<Console, 'log' | 'info' | 'error' | 'warn' | 'debug'>

export const LogProviderContext = createContext<{ logger: Logger }>({ logger: console })

export function LogProvider({ logger, children }: PropsWithChildren<{ logger: Logger }>) {
    return <LogProviderContext.Provider value={{ logger }}>{children}</LogProviderContext.Provider>
}
