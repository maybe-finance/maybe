import { createContext, useContext } from 'react'

export type ModalKey = 'linkAccounts'
export type ModalManagerAction =
    | { type: 'open'; key: ModalKey; props: any }
    | { type: 'close'; key: ModalKey }
export type ModalManagerContext = {
    dispatch(action: ModalManagerAction): void
}
export const ModalManagerContext = createContext<ModalManagerContext | null>(null)

export function useModalManager() {
    const ctx = useContext(ModalManagerContext)

    if (!ctx) throw new Error('useModalManager must be used from within <ModalManager />')

    return ctx
}
