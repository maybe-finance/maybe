import { useCallback } from 'react'
import toast from 'react-hot-toast'
import * as Sentry from '@sentry/react'
import type {
    ConnectCancelEvent,
    ConnectDoneEvent,
    ConnectErrorEvent,
    ConnectRouteEvent,
} from '@finicity/connect-web-sdk'
import { useFinicityApi } from '../api'
import { useAccountContext, useUserAccountContext } from '../providers'
import { useLogger } from './useLogger'
import { BrowserUtil } from '..'

export function useFinicity() {
    const logger = useLogger()

    const { useGenerateConnectUrl } = useFinicityApi()
    const generateConnectUrl = useGenerateConnectUrl()

    const { setExpectingAccounts } = useUserAccountContext()
    const { setAccountManager } = useAccountContext()

    const launch = useCallback(
        async (linkOrPromise: string | Promise<string>) => {
            const toastId = toast.loading('Initializing Finicity...', { duration: 10_000 })

            const [{ FinicityConnect }, link] = await Promise.all([
                import('@finicity/connect-web-sdk'),
                linkOrPromise,
            ])

            toast.dismiss(toastId)

            FinicityConnect.launch(link, {
                onDone(evt: ConnectDoneEvent) {
                    logger.debug(`Finicity Connect onDone event`, evt)
                    setExpectingAccounts(true)
                },
                onError(evt: ConnectErrorEvent) {
                    logger.error(`Finicity Connect exited with error`, evt)
                    Sentry.captureEvent({
                        level: 'error',
                        message: 'FINICITY_CONNECT_ERROR',
                        tags: {
                            'finicity.error.code': evt.code,
                            'finicity.error.reason': evt.reason,
                        },
                    })
                },
                onCancel(evt: ConnectCancelEvent) {
                    logger.debug(`Finicity Connect onCancel event`, evt)
                },
                onUser(evt: any) {
                    //Nothing
                },
                onRoute(evt: ConnectRouteEvent) {
                    //Nothing
                },
            })
        },
        [logger, setExpectingAccounts]
    )

    return {
        launch,
        openFinicity: async (institutionId: string) => {
            launch(generateConnectUrl.mutateAsync(institutionId))
            setAccountManager({ view: 'idle' })
        },
    }
}
