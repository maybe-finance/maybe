import Link from 'next/link'
import { useUserApi } from '@maybe-finance/client/shared'
import { Button } from '@maybe-finance/design-system'
import toast from 'react-hot-toast'
import { useAuth0 } from '@auth0/auth0-react'

export function CountryWaitlist({ country }: { country?: string }) {
    const { logout } = useAuth0()
    const { useDelete } = useUserApi()

    const deleteUser = useDelete({
        onSuccess() {
            toast.success(`Account deleted`)
            setTimeout(() => logout({ logoutParams: { returnTo: window.location.origin } }), 500)
        },
        onError() {
            toast.error(`Error deleting account`)
        },
    })

    return (
        <div className="w-full max-w-md mx-auto">
            <h3 className="text-center">
                Unfortunately we're only accepting users from the US for now
            </h3>
            <div className="mt-4 space-y-4 text-base text-gray-50">
                <p>We hate doing this, but for now we’re only accepting users from the US. Why?</p>
                <p>
                    Well besides not being able to automatically connect to your institution, our
                    financial advisors wouldn’t be able to give you relevant localized advice and
                    would likely breach some regulations.
                </p>
                <p>
                    That being said, we do plan on expanding Maybe to other countries soon. So we’ll
                    let you know via email once we launch Maybe in {country || 'your country'}.
                </p>
            </div>
            <Link href="https://maybe.co" passHref>
                <Button as="a" fullWidth className="mt-8">
                    Got it
                </Button>
            </Link>
            <Button
                variant="warn"
                fullWidth
                className="mt-4"
                disabled={deleteUser.isLoading}
                onClick={() => {
                    if (
                        // eslint-disable-next-line
                        confirm(
                            'Are you sure you want to delete your account? This cannot be undone.'
                        )
                    ) {
                        deleteUser.mutate({})
                    }
                }}
            >
                {deleteUser.isLoading ? 'Deleting account...' : 'Delete my account'}
            </Button>
        </div>
    )
}
