import {
    type ModalKey,
    type ModalManagerAction,
    ModalManagerContext,
    useUserApi,
    useLocalStorage,
} from '@maybe-finance/client/shared'
import { type PropsWithChildren, useReducer, useEffect } from 'react'
import { LinkAccountFlow } from '@maybe-finance/client/features'

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
    const [accountLinkHidden, setAccountLinkHidden] = useLocalStorage('account-link-hidden', false)

    const [state, dispatch] = useReducer(reducer, {
        linkAuth0Accounts: { isOpen: false, props: null },
    })

    const allClosed = Object.values(state).every((v) => v.isOpen === false)

    const { useAuth0Profile } = useUserApi()
    const auth0Profile = useAuth0Profile()

    useEffect(() => {
        const autoPrompt = auth0Profile.data?.autoPromptEnabled === true
        const provider = auth0Profile.data?.suggestedIdentities?.[0]?.provider

        if (autoPrompt && provider && allClosed && !accountLinkHidden) {
            dispatch({
                type: 'open',
                key: 'linkAuth0Accounts',
                props: { secondaryProvider: provider },
            })
        }
    }, [auth0Profile.data, dispatch, allClosed, accountLinkHidden])

    return (
        <ModalManagerContext.Provider value={{ dispatch }}>
            {children}

            <LinkAccountFlow
                isOpen={state.linkAuth0Accounts.isOpen}
                onClose={() => {
                    dispatch({ type: 'close', key: 'linkAuth0Accounts' })
                    setAccountLinkHidden(true)
                }}
                {...state.linkAuth0Accounts.props}
            />
        </ModalManagerContext.Provider>
    )
}
