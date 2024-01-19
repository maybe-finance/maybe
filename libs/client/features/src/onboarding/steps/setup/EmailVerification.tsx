import { useEffect, useRef, useState } from 'react'
import classNames from 'classnames'
import toast from 'react-hot-toast'
import { RiArrowRightLine, RiMailCheckLine, RiMailSendLine, RiQuestionLine } from 'react-icons/ri'
import { AiOutlineLoading3Quarters as LoadingIcon } from 'react-icons/ai'
import { Button, Tooltip } from '@maybe-finance/design-system'
import { useUserApi } from '@maybe-finance/client/shared'
import type { StepProps } from '../StepProps'

export function EmailVerification({ title, onNext }: StepProps) {
    const { useAuthProfile, useResendEmailVerification } = useUserApi()

    const emailVerified = useRef(false)

    const profile = useAuthProfile({
        refetchInterval: emailVerified.current ? false : 5_000,
        onSuccess: (data) => {
            if (data.emailVerified) {
                emailVerified.current = true
            }
        },
    })

    const resendEmailVerification = useResendEmailVerification({
        onSuccess: (data) => {
            if (data && data.success) {
                toast.success('Verification email sent!')
            }
        },
    })

    const [resendDisabled, setResendDisabled] = useState(false)

    useEffect(() => {
        if (resendEmailVerification.isSuccess) {
            // Disable resend button for 10 seconds
            setResendDisabled(true)
            const timeout = setTimeout(() => {
                setResendDisabled(false)
            }, 10_000)
            return () => clearTimeout(timeout)
        }

        return undefined
    }, [resendEmailVerification.isSuccess])

    if (profile.isLoading) {
        // eslint-disable-next-line react/jsx-no-useless-fragment
        return <></>
    }

    if (profile.isError) {
        return (
            <div className="flex justify-center text-gray-100">
                <p>Something went wrong. Please try again.</p>
            </div>
        )
    }

    return (
        <div className="w-full max-w-md mx-auto">
            <div className="flex justify-center items-center">
                <div
                    className={classNames(
                        'flex items-center justify-center w-12 h-12 rounded-2xl border',
                        'border-gray-600 text-white'
                    )}
                    style={{
                        background:
                            'linear-gradient(180deg, rgba(35, 36, 40, 0.2) 0%, rgba(68, 71, 76, 0.2) 100%)',
                    }}
                >
                    {profile.data?.emailVerified ? (
                        <RiMailCheckLine className="w-6 h-6" />
                    ) : (
                        <RiMailSendLine className="w-6 h-6" />
                    )}
                </div>
            </div>
            <h3 className="mt-12 text-center text-pretty">
                {profile.data?.emailVerified ? 'Email verified' : title}
            </h3>
            <div className="text-base text-center">
                {profile.data?.emailVerified ? (
                    <p className="mt-4 text-gray-50">
                        You have successfully verified{' '}
                        <span className="text-gray-25">{profile.data?.email ?? 'your email'}</span>
                    </p>
                ) : (
                    <>
                        <p className="mt-4 text-gray-50">
                            Before we can start setting up your account and connecting to data
                            providers, we&rsquo;ll need to verify your email.
                        </p>
                        <p className="mt-4 text-gray-50">
                            A magic link has been sent to{' '}
                            <span className="text-gray-25">
                                {profile.data?.email ?? 'your email'}
                            </span>
                        </p>
                        <button
                            className="flex items-center justify-center w-full mt-4 text-white hover:text-gray-25 disabled:text-gray-50"
                            disabled={resendEmailVerification.isLoading || resendDisabled}
                            onClick={() => resendEmailVerification.mutate(undefined)}
                        >
                            {resendEmailVerification.isLoading && (
                                <LoadingIcon className="mr-2 w-3 h-3 animate-spin" />
                            )}
                            Haven&rsquo;t received anything? Send it again
                        </button>

                        <Tooltip
                            content={
                                <>
                                    Besides verifying that it&rsquo;s actually you signing up, this
                                    helps us prevent spam registration and keep your account secure.
                                    Verification is also helpful for account recovery in case of a
                                    lost/forgotten password.
                                </>
                            }
                            placement="bottom"
                        >
                            <div className="mt-6 flex items-center justify-center space-x-2">
                                <RiQuestionLine className="w-5 h-5 text-gray-100"></RiQuestionLine>
                                <span className="text-gray-50">
                                    Why do you need to verify my email?
                                </span>
                            </div>
                        </Tooltip>
                    </>
                )}
            </div>
            {profile.data?.emailVerified && (
                <Button className="mt-5" fullWidth onClick={onNext}>
                    Continue setup <RiArrowRightLine className="ml-2 w-5 h-5" />
                </Button>
            )}
        </div>
    )
}
