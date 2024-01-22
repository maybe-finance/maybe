import { useState, type ReactElement } from 'react'
import { Input, InputPassword, Button, Checkbox } from '@maybe-finance/design-system'
import { FullPageLayout } from '@maybe-finance/client/features'
import { signIn, useSession } from 'next-auth/react'
import { useRouter } from 'next/router'
import { useEffect } from 'react'
import Script from 'next/script'
import Link from 'next/link'

export default function RegisterPage() {
    const [firstName, setFirstName] = useState('')
    const [lastName, setLastName] = useState('')
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [isValid, setIsValid] = useState(false)
    const [errorMessage, setErrorMessage] = useState<string | null>(null)
    const [isLoading, setIsLoading] = useState(false)
    const [isAdmin, setIsAdmin] = useState<boolean>(false)
    const [isOnboarded, setIsOnboarded] = useState<boolean>(false)

    const { data: session } = useSession()
    const router = useRouter()

    useEffect(() => {
        if (session) router.push('/')
    }, [session, router])

    const onSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault()

        setErrorMessage(null)
        setFirstName('')
        setLastName('')
        setEmail('')
        setPassword('')
        setIsLoading(true)

        const response = await signIn('credentials', {
            email,
            password,
            firstName,
            lastName,
            role: isAdmin ? 'admin' : 'user',
            redirect: false,
            onboarded: isOnboarded ? true : false,
        })

        if (response && response.error) {
            setErrorMessage(response.error)
            setIsLoading(false)
        }
    }

    return (
        <>
            <Script
                src="https://cdnjs.cloudflare.com/ajax/libs/zxcvbn/4.4.2/zxcvbn.js"
                strategy="lazyOnload"
            />
            <div className="absolute inset-0 flex flex-col items-center justify-center">
                <div className="p-px w-96 bg-white bg-opacity-10 card-light rounded-3xl radial-gradient-background">
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
                                name="firstName"
                                label="First name"
                                value={firstName}
                                onChange={(e) => setFirstName(e.currentTarget.value)}
                            />
                            <Input
                                type="text"
                                name="lastName"
                                label="Last name"
                                value={lastName}
                                onChange={(e) => setLastName(e.currentTarget.value)}
                            />
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
                                showPasswordRequirements={!isValid}
                                onValidityChange={(checks) => {
                                    const passwordValid =
                                        checks.filter((c) => !c.isValid).length === 0
                                    setIsValid(passwordValid)
                                }}
                                onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                                    setPassword(e.target.value)
                                }
                            />

                            {errorMessage && password.length === 0 ? (
                                <div className="py-1 text-center text-red text-sm">
                                    {errorMessage}
                                </div>
                            ) : null}

                            <AuthDevTools
                                isAdmin={isAdmin}
                                setIsAdmin={setIsAdmin}
                                isOnboarded={isOnboarded}
                                setIsOnboarded={setIsOnboarded}
                            />

                            <Button
                                type="submit"
                                disabled={!isValid}
                                variant={isValid ? 'primary' : 'secondary'}
                                isLoading={isLoading}
                            >
                                Register
                            </Button>
                            <div className="text-sm text-gray-50 pt-2">
                                <div>
                                    Already have an account?{' '}
                                    <Link
                                        className="hover:text-cyan-400 underline font-medium"
                                        href="/login"
                                    >
                                        Sign in
                                    </Link>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </>
    )
}

type AuthDevToolsProps = {
    isAdmin: boolean
    setIsAdmin: (isAdmin: boolean) => void
    isOnboarded: boolean
    setIsOnboarded: (isOnboarded: boolean) => void
}

function AuthDevTools({ isAdmin, setIsAdmin, isOnboarded, setIsOnboarded }: AuthDevToolsProps) {
    return process.env.NODE_ENV === 'development' ? (
        <div className="my-2 p-2 border border-red-300 rounded-md">
            <h6 className="flex text-red">
                Dev Tools <i className="ri-tools-fill ml-1.5" />
            </h6>
            <p className="text-sm my-2">
                This section will NOT show in production and is solely for making testing easier.
            </p>

            <div className="flex items-center text-sm mt-4">
                <Checkbox checked={isAdmin} onChange={setIsAdmin} label="Create Admin user?" />
                <Checkbox checked={isAdmin} onChange={setIsAdmin} label="Create Admin user?" />
            </div>
        </div>
    ) : null
}

RegisterPage.getLayout = function getLayout(page: ReactElement) {
    return <FullPageLayout>{page}</FullPageLayout>
}

RegisterPage.isPublic = true
