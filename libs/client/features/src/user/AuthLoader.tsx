import { useAuth0 } from '@auth0/auth0-react'
import { LoadingSpinner } from '@maybe-finance/design-system'
import { SharedType } from '@maybe-finance/shared'
import { useMemo } from 'react'
import { RiInformationLine } from 'react-icons/ri'

export function AuthLoader({ message }: { message?: string }): JSX.Element {
    const { user } = useAuth0()

    const currentLoginType = useMemo(() => {
        const primaryIdentity =
            user && user[SharedType.Auth0CustomNamespace.PrimaryIdentity]?.provider

        return primaryIdentity ? primaryIdentity : undefined
    }, [user])

    return (
        <>
            {message && (
                <div className="fixed top-5 px-10 w-full">
                    <div className="flex items-center text-sm bg-gray-500 px-4 py-2 rounded">
                        <RiInformationLine className="w-6 h-6 mr-3 shrink-0" />
                        <p>
                            You are currently logged in to your{' '}
                            <span className="text-white">
                                {currentLoginType === 'apple' ? 'Apple ' : 'Email/Password '}
                            </span>{' '}
                            account. Please login with your{' '}
                            <span className="text-white">
                                {currentLoginType === 'apple' ? 'Email/Password ' : 'Apple '}
                                account
                            </span>
                            , and we'll merge the data between the two (no data will be lost).
                        </p>
                    </div>
                </div>
            )}

            <div className="flex flex-col items-center justify-center h-screen transform -translate-y-16">
                <LoadingSpinner />
                <p className="mt-4 text-base text-gray-50 animate-pulse">{message || ''}</p>
            </div>
        </>
    )
}
