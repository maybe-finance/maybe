import * as Sentry from '@sentry/react'
import type { Logger } from '../providers/LogProvider'
import type {
    TellerConnectEnrollment,
    TellerConnectFailure,
    TellerConnectOptions,
} from 'teller-connect-react'

type TellerEnvironment = 'sandbox' | 'development' | 'production' | undefined
type TellerAccountSelection = 'disabled' | 'single' | 'multiple' | undefined

export const getTellerConfig = (logger: Logger, institutionId: string | undefined) => {
    return {
        applicationId: process.env.NEXT_PUBLIC_TELLER_APP_ID ?? 'ADD_TELLER_APP_ID',
        environment: (process.env.NEXT_PUBLIC_TELLER_ENV as TellerEnvironment) ?? 'sandbox',
        selectAccount: 'disabled' as TellerAccountSelection,
        ...(institutionId !== undefined ? { institution: institutionId } : {}),
        onInit: () => {
            logger.debug(`Teller Connect has initialized`)
        },
        onSuccess: (enrollment: TellerConnectEnrollment) => {
            logger.debug(`User enrolled successfully`, enrollment)
        },
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
