import { useEffect, useState } from 'react'
import * as Sentry from '@sentry/react'
import type { Logger } from '../providers/LogProvider'
import toast from 'react-hot-toast'
import { useAccountContext } from '../providers'
import { useTellerApi } from '../api'
import type {
    TellerConnectEnrollment,
    TellerConnectFailure,
    TellerConnectOptions,
    TellerConnectInstance,
} from 'teller-connect-react'
import useScript from 'react-script-hook'
type TellerEnvironment = 'sandbox' | 'development' | 'production' | undefined
type TellerAccountSelection = 'disabled' | 'single' | 'multiple' | undefined
const TC_JS = 'https://cdn.teller.io/connect/connect.js'

// Create the base configuration for Teller Connect
export const useTellerConfig = (logger: Logger) => {
    return {
        applicationId: process.env.NEXT_PUBLIC_TELLER_APP_ID ?? 'ADD_TELLER_APP_ID',
        environment: (process.env.NEXT_PUBLIC_TELLER_ENV as TellerEnvironment) ?? 'sandbox',
        selectAccount: 'disabled' as TellerAccountSelection,
        onInit: () => {
            logger.debug(`Teller Connect has initialized`)
        },
        onSuccess: {},
        onExit: () => {
            logger.debug(`Teller Connect exited`)
        },
        onFailure: (failure: TellerConnectFailure) => {
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
    } as TellerConnectOptions
}

// Custom implementation of useTellerHook to handle institution id being passed in
export const useTellerConnect = (options: TellerConnectOptions, logger: Logger) => {
    const { useHandleEnrollment } = useTellerApi()
    const handleEnrollment = useHandleEnrollment()
    const { setAccountManager } = useAccountContext()
    const [loading, error] = useScript({
        src: TC_JS,
        checkForExisting: true,
    })

    const [teller, setTeller] = useState<TellerConnectInstance | null>(null)
    const [iframeLoaded, setIframeLoaded] = useState(false)

    const createTellerInstance = (institutionId: string) => {
        return createTeller(
            {
                ...options,
                onSuccess: async (enrollment: TellerConnectEnrollment) => {
                    logger.debug('User enrolled successfully')
                    try {
                        await handleEnrollment.mutateAsync({
                            institution: {
                                id: institutionId!,
                                name: enrollment.enrollment.institution.name,
                            },
                            enrollment,
                        })
                    } catch (error) {
                        toast.error(`Failed to add account`)
                    }
                },
                institution: institutionId,
                onInit: () => {
                    setIframeLoaded(true)
                    options.onInit && options.onInit()
                },
            },
            window.TellerConnect.setup
        )
    }

    useEffect(() => {
        if (loading) {
            return
        }

        if (!options.applicationId) {
            return
        }

        if (error || !window.TellerConnect) {
            console.error('Error loading TellerConnect:', error)
            return
        }

        if (teller != null) {
            teller.destroy()
        }

        return () => teller?.destroy()
    }, [
        loading,
        error,
        options.applicationId,
        options.enrollmentId,
        options.connectToken,
        options.products,
    ])

    const ready = teller != null && (!loading || iframeLoaded)

    const logIt = () => {
        if (!options.applicationId) {
            console.error('teller-connect-react: open() called without a valid applicationId.')
        }
    }

    return {
        error,
        ready,
        open: (institutionId: string) => {
            logIt()
            const tellerInstance = createTellerInstance(institutionId)
            tellerInstance.open()
            setAccountManager({ view: 'idle' })
        },
    }
}

interface ManagerState {
    teller: TellerConnectInstance | null
    open: boolean
}

export const createTeller = (
    config: TellerConnectOptions,
    creator: (config: TellerConnectOptions) => TellerConnectInstance
) => {
    const state: ManagerState = {
        teller: null,
        open: false,
    }

    if (typeof window === 'undefined' || !window.TellerConnect) {
        throw new Error('TellerConnect is not loaded')
    }

    state.teller = creator({
        ...config,
        onExit: () => {
            state.open = false
            config.onExit && config.onExit()
        },
    })

    const open = () => {
        if (!state.teller) {
            return
        }

        state.open = true
        state.teller.open()
    }

    const destroy = () => {
        if (!state.teller) {
            return
        }

        state.teller.destroy()
        state.teller = null
    }

    return {
        open,
        destroy,
    }
}
