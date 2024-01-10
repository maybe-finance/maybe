import type { PlaidLinkOnSuccess, PlaidLinkOnExit } from 'react-plaid-link'
import { useAccountConnectionApi } from '@maybe-finance/client/shared'
import { Button } from '@maybe-finance/design-system'
import type { SharedType } from '@maybe-finance/shared'
import { useEffect } from 'react'
import { usePlaidLink } from 'react-plaid-link'

type PlaidLinkUpdateButtonProps = {
    accountConnectionId: number
    onSuccess: PlaidLinkOnSuccess
    onExit?: PlaidLinkOnExit
    mode: SharedType.PlaidLinkUpdateMode
}

export function PlaidLinkUpdateButton({
    accountConnectionId,
    onSuccess,
    onExit,
    mode,
}: PlaidLinkUpdateButtonProps) {
    const { useCreatePlaidLinkToken } = useAccountConnectionApi()

    const createLinkToken = useCreatePlaidLinkToken(mode)

    const token = createLinkToken.data?.token ?? null

    const { ready, open } = usePlaidLink({
        token,
        onSuccess,
        onExit,
    })

    useEffect(() => {
        if (ready) {
            open()
        }
    }, [ready, open])

    return (
        <Button
            variant="primary"
            onClick={() => createLinkToken.mutate(accountConnectionId)}
            disabled={createLinkToken.isLoading}
        >
            {mode === 'reconnect' ? 'Reconnect' : 'Update'}
        </Button>
    )
}

export default PlaidLinkUpdateButton
