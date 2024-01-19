import { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import classNames from 'classnames'
import {
    RiAnticlockwise2Line,
    RiArrowGoBackFill,
    RiArrowRightLine,
    RiDownloadLine,
    RiShareForwardLine,
} from 'react-icons/ri'
import { AiOutlineLoading3Quarters as LoadingIcon } from 'react-icons/ai'
import { Button, Tooltip } from '@maybe-finance/design-system'
import { Confetti, MaybeCard, MaybeCardShareModal, useUserApi } from '@maybe-finance/client/shared'
import type { StepProps } from './StepProps'
import { UserUtil } from '@maybe-finance/shared'

export function Welcome({ title: stepTitle, onNext }: StepProps) {
    const { useMemberCardDetails, useUpdateProfile } = useUserApi()

    const { data } = useMemberCardDetails()

    const updateProfile = useUpdateProfile({ onSuccess: undefined })

    const [isCardFlipped, setIsCardFlipped] = useState(false)
    const [isShareModalOpen, setIsShareModalOpen] = useState(false)

    const {
        handleSubmit,
        formState: { isSubmitting, isValid },
        watch,
        setValue,
    } = useForm<{
        title: string
    }>({
        mode: 'onChange',
    })

    const title = watch('title')

    useEffect(() => {
        if (data && !title)
            setValue('title', data.title ?? UserUtil.randomUserTitle(), {
                shouldValidate: true,
            })
    }, [title, data, setValue])

    return (
        <>
            <form
                className="flex items-center justify-center max-w-5xl mx-auto mt-16 md:mt-[20vh] gap-16 md:gap-32 flex-wrap md:flex-nowrap pb-24"
                onSubmit={handleSubmit(async (data) => {
                    await updateProfile.mutateAsync(data)
                    await onNext()
                })}
            >
                <div className="max-w-md grow">
                    <img src="/assets/maybe.svg" className="h-8" alt="Maybe" />
                    <h3 className="mt-14 text-pretty">{stepTitle}</h3>
                    <p className="mt-2 text-base text-gray-50">
                        We made you a little something to celebrate you taking your first steps in
                        Maybe. Feel free to share and don&rsquo;t forget to flip the card!
                    </p>
                    <Button type="submit" className="mt-14" disabled={!isValid}>
                        Start exploring
                        {isSubmitting ? (
                            <LoadingIcon className="w-5 h-5 ml-2 animate-spin" />
                        ) : (
                            <RiArrowRightLine className="w-5 h-5 ml-2" />
                        )}
                    </Button>
                </div>
                <div className="relative shrink-0">
                    <fieldset className="flex items-center justify-center border border-gray-400 border-dashed rounded-3xl">
                        <legend className="mx-auto text-sm text-gray-100 px-7">
                            Your Maybe card
                        </legend>
                        <MaybeCard
                            variant="onboarding"
                            flipped={isCardFlipped}
                            details={data ? { ...data, title } : undefined}
                        />
                        <MaybeCardShareModal
                            isOpen={isShareModalOpen}
                            onClose={() => setIsShareModalOpen(false)}
                            cardUrl={data?.cardUrl || ''}
                            card={{ details: data }}
                        />
                    </fieldset>
                    <div className="flex justify-center w-full gap-3 mt-6">
                        <Tooltip content="Share" placement="bottom">
                            <div className="w-full">
                                <Button
                                    fullWidth
                                    type="button"
                                    variant="secondary"
                                    disabled={!data}
                                    onClick={() => {
                                        // Make sure title is persisted for sharing
                                        updateProfile.mutateAsync({ title })

                                        setIsShareModalOpen(true)
                                    }}
                                >
                                    <RiShareForwardLine className="w-5 h-5 text-gray-50" />
                                </Button>
                            </div>
                        </Tooltip>
                        <Tooltip content="Download" placement="bottom">
                            <div className="w-full">
                                <Button
                                    as="a"
                                    fullWidth
                                    variant="secondary"
                                    className={classNames(
                                        !data && 'opacity-50 pointer-events-none'
                                    )}
                                    href={data?.imageUrl}
                                    download="/assets/maybe-card.png"
                                >
                                    <RiDownloadLine className="w-5 h-5 text-gray-50" />
                                </Button>
                            </div>
                        </Tooltip>
                        <Tooltip content="Randomize title" placement="bottom">
                            <div className="w-full">
                                <Button
                                    fullWidth
                                    type="button"
                                    variant="secondary"
                                    onClick={() =>
                                        setValue('title', UserUtil.randomUserTitle(title), {
                                            shouldValidate: true,
                                        })
                                    }
                                >
                                    <RiArrowGoBackFill className="w-5 h-5 text-gray-50" />
                                </Button>
                            </div>
                        </Tooltip>
                        <Tooltip content="Flip card" placement="bottom">
                            <div className="w-full">
                                <Button
                                    fullWidth
                                    type="button"
                                    variant="secondary"
                                    onClick={() => setIsCardFlipped((flipped) => !flipped)}
                                >
                                    <RiAnticlockwise2Line className="w-5 h-5 text-gray-50" />
                                </Button>
                            </div>
                        </Tooltip>
                    </div>
                </div>
            </form>
            <Confetti respawn={false} gravity={0.02} />
        </>
    )
}
