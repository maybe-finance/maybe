import {
    useAccountConnectionApi,
    useAccountContext,
    useFinicity,
} from '@maybe-finance/client/shared'
import { Button } from '@maybe-finance/design-system'

type FinicityFixConnectButtonProps = {
    accountConnectionId: number
}

export default function FinicityFixConnectButton({
    accountConnectionId,
}: FinicityFixConnectButtonProps) {
    const { launch } = useFinicity()
    const { setAccountManager } = useAccountContext()

    const { useCreateFinicityFixConnectUrl } = useAccountConnectionApi()

    const createFixConnectUrl = useCreateFinicityFixConnectUrl({
        onSuccess({ link }) {
            launch(link)
            setAccountManager({ view: 'idle' })
        },
    })

    return (
        <Button
            variant="primary"
            onClick={() => createFixConnectUrl.mutate(accountConnectionId)}
            disabled={createFixConnectUrl.isLoading}
        >
            Fix connection
        </Button>
    )
}
