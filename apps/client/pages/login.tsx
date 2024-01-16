import { useState, type ReactElement } from 'react'
import { FullPageLayout } from '@maybe-finance/client/features'
import { Input, InputPassword, Button, Dialog, Toast } from '@maybe-finance/design-system'
import { signIn, useSession } from 'next-auth/react'
import { useRouter } from 'next/router'
import { useEffect } from 'react'
import Script from 'next/script'
import Link from 'next/link'

export default function LoginPage() {
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [isValid, setIsValid] = useState(false)

    // FIXME - move this to a separate component/hook?
    const [forgotPasswordEmail, setForgotPasswordEmail] = useState('')
    const [showForgotPasswordDialog, setShowForgotPasswordDialog] = useState(false)
    const [sendResetPasswordEmailLoading, setSendResetPasswordEmailLoading] = useState(false)
    const [showResetPasswordSuccess, setShowResetPasswordSuccess] = useState(false)

    const [errorMessage, setErrorMessage] = useState<string | null>(null)
    const [isLoading, setIsLoading] = useState(false)

    const { data: session } = useSession()
    const router = useRouter()

    useEffect(() => {
        if (session) {
            router.push('/')
        }
    }, [session, router])

    const onSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault()
        setErrorMessage(null)
        setPassword('')
        setIsLoading(true)

        const response = await signIn('credentials', {
            email,
            password,
            redirect: false,
        })

        if (response && response.error) {
            setErrorMessage(response.error)
            setIsLoading(false)
            setIsValid(false)
        }
    }

    const onPasswordChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setErrorMessage(null)
        setPassword(e.target.value)
        setIsValid(e.target.value.length > 0)
    }

    const sendResetPasswordEmail = async () => {
        setSendResetPasswordEmailLoading(true)

        const response = await fetch('/api/auth/reset-password', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email: forgotPasswordEmail,
            }),
        })

        if (response.ok) {
            setShowResetPasswordSuccess(true)
            setSendResetPasswordEmailLoading(false)
            setForgotPasswordEmail('')
        }
    }

    return (
        <>
            <Script
                src="https://cdnjs.cloudflare.com/ajax/libs/zxcvbn/4.4.2/zxcvbn.js"
                strategy="lazyOnload"
            />
            <div className="absolute inset-0 flex flex-col items-center justify-center">
                <div className="p-px w-80 md:w-96 bg-white bg-opacity-10 card-light rounded-3xl radial-gradient-background">
                    <div className="bg-black bg-opacity-75 p-8 rounded-3xl w-full h-full items-center flex flex-col radial-gradient-background-dark">
                        <img
                            className="mb-8"
                            src="/assets/maybe-box.svg"
                            alt="Maybe Finance Logo"
                            height={120}
                            width={120}
                        />
                        <form className="space-y-4 w-full px-4" onSubmit={onSubmit}>
                            <Input
                                type="text"
                                name="email"
                                label="Email"
                                value={email}
                                onChange={(e) => setEmail(e.currentTarget.value)}
                            />

                            <InputPassword
                                autoComplete="password"
                                name="password"
                                label="Password"
                                value={password}
                                onChange={onPasswordChange}
                                showComplexityBar={false}
                            />

                            {errorMessage && password.length === 0 ? (
                                <div className="py-1 text-center text-red text-sm">
                                    {errorMessage}
                                </div>
                            ) : null}

                            <Button
                                type="submit"
                                disabled={!isValid || isLoading}
                                variant={isValid ? 'primary' : 'secondary'}
                                isLoading={isLoading}
                            >
                                Log in
                            </Button>
                            <div className="text-sm text-gray-50 pt-2">
                                <div>
                                    Don&apos;t have an account?{' '}
                                    <Link
                                        className="hover:text-cyan-400 underline font-medium"
                                        href="/register"
                                    >
                                        Sign up
                                    </Link>
                                </div>
                            </div>

                            <Dialog
                                onClose={() => {
                                    setShowForgotPasswordDialog(false)
                                    setShowResetPasswordSuccess(false)
                                    setForgotPasswordEmail('')
                                }}
                                isOpen={showForgotPasswordDialog}
                            >
                                <Dialog.Title>Forgot password?</Dialog.Title>
                                <Dialog.Content>
                                    {showResetPasswordSuccess && (
                                        <Toast variant="success" className="my-2">
                                            If the email you provided exists, we&apos;ve sent you a
                                            password reset email.
                                        </Toast>
                                    )}

                                    <Input
                                        type="text"
                                        label="Email"
                                        value={forgotPasswordEmail}
                                        onChange={(e) =>
                                            setForgotPasswordEmail(e.currentTarget.value)
                                        }
                                    />
                                </Dialog.Content>
                                <Dialog.Actions>
                                    <Button
                                        type="button"
                                        disabled={sendResetPasswordEmailLoading}
                                        onClick={() => sendResetPasswordEmail()}
                                        fullWidth
                                    >
                                        Send Password Reset Email
                                    </Button>
                                </Dialog.Actions>
                            </Dialog>

                            <div className="text-sm text-gray-50 mt-2">
                                <button
                                    className="hover:text-cyan-400 underline font-medium"
                                    type="button"
                                    onClick={() => setShowForgotPasswordDialog(true)}
                                >
                                    Forgot password?
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </>
    )
}

LoginPage.getLayout = function getLayout(page: ReactElement) {
    return <FullPageLayout>{page}</FullPageLayout>
}

LoginPage.isPublic = true
