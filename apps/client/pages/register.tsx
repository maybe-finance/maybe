import type { ReactElement } from 'react'
import { Input, InputPassword } from '@maybe-finance/design-system'
import { FullPageLayout } from '@maybe-finance/client/features'
import { useSession } from 'next-auth/react'
import { useRouter } from 'next/router'
import { useEffect } from 'react'

export default function RegisterPage() {
    const { data: session } = useSession()
    const router = useRouter()

    useEffect(() => {
        if (session) router.push('/')
    }, [session, router])

    // _app.tsx will automatically redirect if not authenticated
    return (
        <div className="absolute inset-0 flex items-center justify-center">
            <div className="text-4xl font-bold text-white">THIS IS THE LOGIN PAGE</div>
            <Input type="text" placeholder="Email" />
            <InputPassword placeholder="Password" />
        </div>
    )
}

RegisterPage.getLayout = function getLayout(page: ReactElement) {
    return <FullPageLayout>{page}</FullPageLayout>
}

RegisterPage.isPublic = true
