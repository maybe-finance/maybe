import * as Sentry from '@sentry/react'
import { DateTime } from 'luxon'
import { useEffect, useState } from 'react'
import { usePlaidLink } from 'react-plaid-link'
import { BrowserUtil } from '..'
import { usePlaidApi } from '../api'
import { useAccountContext } from '../providers'
import { useLogger } from './useLogger'
import toast from 'react-hot-toast'
import axios from 'axios'
import { useRouter } from 'next/router'

/**
 * Opens Plaid link
 *
 * Depending on mode set, different behavior:
 *
 * - `default` - user explicitly opens link flow by clicking
 * - `oauth` - Link flow is implicitly re-initialized based on a prior link session
 *
 * @see https://plaid.com/docs/link/oauth/
 */
export function usePlaid(mode: 'default' | 'oauth' = 'default') {
    const logger = useLogger()
    const router = useRouter()

    const [clientToken, setClientToken] = useState<string | null>(null)

    const { setAccountManager } = useAccountContext()
    const { useExchangePublicToken, useCreateLinkToken, useGetLinkToken } = usePlaidApi()

    const exchangePublicToken = useExchangePublicToken()
    const createLinkToken = useCreateLinkToken()
    const getLinkToken = useGetLinkToken({ enabled: mode === 'oauth' })

    const {
        ready: isPlaidLinkReady,
        open: openPlaidLink,
        error: plaidError,
    } = usePlaidLink({
        token: mode === 'default' ? clientToken : getLinkToken.data?.token ?? null,
        receivedRedirectUri: mode === 'default' ? undefined : window.location.href,
        onSuccess: async (publicToken, metadata) => {
            try {
                await exchangePublicToken.mutateAsync({
                    token: publicToken,
                    institution: metadata.institution,
                })

                if (mode === 'oauth') {
                    router.push('/accounts')
                }
            } catch (e) {
                if (axios.isAxiosError(e)) {
                    if (e.response?.data.errors[0].title === 'USD_ONLY') {
                        toast.error('Non-USD accounts are not supported yet.')
                    }

                    if (e.response?.data.errors[0].title === 'MAX_ACCOUNT_CONNECTIONS') {
                        toast.error(
                            'You have reached the maximum number of connections per user account.  Please reach out to us or delete an existing connection to continue.',
                            {
                                duration: 12000,
                            }
                        )
                    }
                }
            }
        },
        // https://plaid.com/docs/link/web/#onexit
        onExit: (error, metadata) => {
            if (error) {
                const { error_code, error_type, error_message, display_message } = error
                BrowserUtil.trackIntercomEvent(`PLAID_LINK_EXIT_ERROR`, {
                    error_type,
                    error_code,
                    error_message,
                    display_message,
                    reference: 'https://plaid.com/docs/errors/',
                })
            }

            BrowserUtil.trackIntercomEvent('PLAID_EXIT_EVENT', {
                ...error,
                ...metadata,
            })
        },
        // https://plaid.com/docs/link/web/#onevent
        onEvent: (event, metadata) => {
            // Capture all events to Sentry (will be grouped)
            Sentry.captureEvent({
                level: event === 'ERROR' ? 'error' : 'info',
                message: `PLAID_LINK_${event}`,
                timestamp: DateTime.fromISO(metadata.timestamp).toSeconds(),
                tags: {
                    ...metadata,
                },
            })

            // Capture all events to Intercom
            BrowserUtil.trackIntercomEvent(event, metadata)

            logger.debug(
                `Plaid link event: ${event} for session ID ${metadata.link_session_id}`,
                metadata
            )
        },
    })

    useEffect(() => {
        if (isPlaidLinkReady) {
            openPlaidLink()

            if (mode === 'default') {
                setAccountManager({ view: 'idle' })
            } else {
                console.debug('Re-initialized Plaid link successfully with OAuth')
            }
        }
    }, [isPlaidLinkReady, openPlaidLink, setAccountManager, mode, getLinkToken.data])

    return {
        openPlaid: async (institutionId: string) => {
            toast('Initializing Plaid...', { duration: 2_000 })

            if (mode === 'default') {
                const { token } = await createLinkToken.mutateAsync({ institutionId })
                setClientToken(token)
            }
        },
        isPlaidLinkReady,
        fetchTokenError: mode === 'oauth' && (getLinkToken.failureCount > 1 || plaidError != null),
    }
}
