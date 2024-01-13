import {
    type ModalKey,
    type ModalManagerAction,
    ModalManagerContext,
} from '@maybe-finance/client/shared'
import { type PropsWithChildren, useReducer } from 'react'

function reducer(
    state: Record<ModalKey, { isOpen: boolean; props: any }>,
    action: ModalManagerAction
) {
    switch (action.type) {
        case 'open':
            return { ...state, [action.key]: { isOpen: true, props: action.props } }
        case 'close':
            return { ...state, [action.key]: { isOpen: false, props: null } }
    }
}

/**
 * Manages auto-prompt modals and regular modals to avoid stacking collisions
 */
export default function ModalManager({ children }: PropsWithChildren) {
    const [, dispatch] = useReducer(reducer, {
        linkAuth0Accounts: { isOpen: false, props: null },
    })

    return (
        <ModalManagerContext.Provider value={{ dispatch }}>{children}</ModalManagerContext.Provider>
    )
}
