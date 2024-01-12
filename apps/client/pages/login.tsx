import type { ReactElement } from 'react'
import { useState } from 'react'
import { FullPageLayout } from '@maybe-finance/client/features'
import { Input, InputPassword, Button } from '@maybe-finance/design-system'
import { AiOutlineLoading3Quarters as LoadingIcon } from 'react-icons/ai'
import { signIn, useSession } from 'next-auth/react'
import { useRouter } from 'next/router'
import { useEffect } from 'react'
import Script from 'next/script'

export default function LoginPage() {
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [isValid, setIsValid] = useState(false)

    const { data: session } = useSession()
    const router = useRouter()

    useEffect(() => {
        if (session) router.push('/')
    }, [session, router])

    const onSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault()
        setEmail('')
        setPassword('')
        await signIn('credentials', {
            email,
            password,
            redirect: false,
        })
    }

    // _app.tsx will automatically redirect if not authenticated
    return (
        <>
            <Script
                src="https://cdnjs.cloudflare.com/ajax/libs/zxcvbn/4.4.2/zxcvbn.js"
                strategy="lazyOnload"
            />
            <div className="absolute inset-0 flex flex-col items-center justify-center">
                <img
                    className="mb-8"
                    src="/assets/maybe.svg"
                    alt="Maybe Finance Logo"
                    height={140}
                    width={140}
                />
                <form className="space-y-4" onSubmit={onSubmit}>
                    <Input
                        type="text"
                        label="Email"
                        value={email}
                        onChange={(e) => setEmail(e.currentTarget.value)}
                    />

                    <InputPassword
                        autoComplete="password"
                        label="Password"
                        value={password}
                        showPasswordRequirements={!isValid}
                        onValidityChange={(checks) => {
                            const passwordValid = checks.filter((c) => !c.isValid).length === 0
                            setIsValid(passwordValid)
                        }}
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                            setPassword(e.target.value)
                        }
                    />

                    <Button
                        type="submit"
                        disabled={!isValid}
                        variant={isValid ? 'primary' : 'secondary'}
                    >
                        Log in
                    </Button>
                </form>
            </div>
        </>
    )
}

LoginPage.getLayout = function getLayout(page: ReactElement) {
    return <FullPageLayout>{page}</FullPageLayout>
}

LoginPage.isPublic = true
