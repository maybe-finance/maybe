import { useState } from 'react'
import toast from 'react-hot-toast'
import * as Sentry from '@sentry/react'
import { useTellerConnect } from 'teller-connect-react'
import { useAccountContext, useUserAccountContext } from '../providers'
import { useLogger } from './useLogger'

type TellerFailure = {
    type: 'payee' | 'payment'
    code: 'timeout' | 'error'
    message: string
}

export function useTeller() {
    const logger = useLogger()

    const [institutionId, setInstitutionId] = useState<string | null>(null)

    const { setExpectingAccounts } = useUserAccountContext()
    const { setAccountManager } = useAccountContext()

    const tellerConfig = {
        applicationId: process.env.NEXT_PUBLIC_TELLER_APP_ID,
        institution: institutionId,
        environment: process.env.NEXT_PUBLIC_TELLER_ENV,
        selectAccount: 'disabled',
        onInit: () => {
            toast.dismiss(toastId)
            logger.debug(`Teller Connect has initialized`)
        },
        onSuccess: (enrollment) => {
            logger.debug(`User enrolled successfully`, enrollment)
            console.log(enrollment)
            setExpectingAccounts(true)
        },
        onExit: () => {
            logger.debug(`Teller Connect exited`)
        },
        onFailure: (failure: TellerFailure) => {
            logger.error(`Teller Connect exited with error`, failure)
            Sentry.captureEvent({
                level: 'error',
                message: 'TELLER_CONNECT_ERROR',
                tags: {
                    'teller.error.code': failure.code,
                    'teller.error.message': failure.message,
                },
            })
        },
    }

    const { open, ready } = useTellerConnect(tellerConfig)

    useEffect(() => {
        if (ready) {
            open()

            if (selectAccount === 'disabled') {
                setAccountManager({ view: 'idle' })
            }
        }
    }, [ready, open, setAccountManager])

    return {
        openTeller: async (institutionId: string) => {
            toast('Initializing Teller...', { duration: 2_000 })
            setInstitutionId(institutionId)
        },
        ready,
    }
}
