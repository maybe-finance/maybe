import { useAuth0 } from '@auth0/auth0-react'
import { LoadingSpinner } from '@maybe-finance/design-system'
import { useRouter } from 'next/router'
import { useEffect } from 'react'

export default function RegisterPage() {
    const { isAuthenticated } = useAuth0()
    const router = useRouter()

    useEffect(() => {
        if (isAuthenticated) router.push('/')
    }, [isAuthenticated, router])

    // _app.tsx will automatically redirect if not authenticated
    return (
        <div className="absolute inset-0 flex items-center justify-center">
            <LoadingSpinner />
        </div>
    )
}
