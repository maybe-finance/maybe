import { useState } from 'react'
import { Controller, useForm } from 'react-hook-form'
import { useAuth0 } from '@auth0/auth0-react'
import classNames from 'classnames'
import { AiOutlineLoading3Quarters as LoadingIcon } from 'react-icons/ai'
import {
    RiAnticlockwise2Line,
    RiAppleFill,
    RiArrowGoBackFill,
    RiDownloadLine,
    RiShareForwardLine,
} from 'react-icons/ri'
import { UserIdentityList } from '../user-details/UserIdentityList'
import {
    Button,
    DatePicker,
    FractionalCircle,
    Input,
    LoadingPlaceholder,
    Tooltip,
} from '@maybe-finance/design-system'
import {
    BrowserUtil,
    MaybeCard,
    MaybeCardShareModal,
    useUserApi,
} from '@maybe-finance/client/shared'
import { DateUtil, UserUtil } from '@maybe-finance/shared'
import { DeleteUserButton } from './DeleteUserButton'
import { DateTime } from 'luxon'

export function UserDetails() {
    const { logout } = useAuth0()
    const { useProfile, useAuth0Profile, useUpdateProfile } = useUserApi()

    const auth0ProfileQuery = useAuth0Profile()
    const updateProfileQuery = useUpdateProfile()

    const profileQuery = useProfile()
    const profile = profileQuery.data

    if (profileQuery.error) {
        return <p className="text-gray-50">Something went wrong loading your profile...</p>
    }

    return (
        <div className="mt-6 space-y-10 max-w-lg">
            <section>
                <h4 className="text-lg uppercase">Profile</h4>
                <LoadingPlaceholder isLoading={profileQuery.isLoading}>
                    {profile && (
                        <ProfileForm
                            defaultValues={{
                                firstName: profile.firstName ?? '',
                                lastName: profile.lastName ?? '',
                                dob: DateUtil.dateTransform(profile.dob!),
                            }}
                            onSubmit={(data) => {
                                updateProfileQuery.mutate(data)
                            }}
                            isSubmitting={updateProfileQuery.isLoading}
                        />
                    )}
                </LoadingPlaceholder>
            </section>

            <section>
                <h4 className="text-lg uppercase">Account</h4>
                <LoadingPlaceholder isLoading={profileQuery.isLoading}>
                    <div className="text-base">
                        <p className="text-gray-50 mb-2">Email address</p>
                        <form>
                            <Input
                                readOnly
                                disabled
                                value={profileQuery.data?.email ?? 'Loading...'}
                                type="text"
                            />
                        </form>
                        {auth0ProfileQuery.data?.primaryIdentity.provider === 'apple' && (
                            <div className="flex items-center gap-x-1 mt-2 text-gray-100">
                                <span className="text-sm">Apple identity</span>
                                <RiAppleFill className="w-3 h-3" />
                            </div>
                        )}
                    </div>

                    {auth0ProfileQuery.data && (
                        <UserIdentityList profile={auth0ProfileQuery.data} />
                    )}
                </LoadingPlaceholder>
            </section>

            <section>
                <MaybeCardSection />
            </section>

            <section>
                <h4 className="text-lg uppercase">Danger Zone</h4>
                <p className="text-base text-gray-100 mb-4">
                    Deleting your account is a permanent action. If you delete your account, you
                    will no longer be able to sign and all data will be deleted.
                </p>
                <DeleteUserButton
                    onDelete={() => logout({ logoutParams: { returnTo: window.location.origin } })}
                />
            </section>
        </div>
    )
}

type ProfileFields = {
    firstName: string
    lastName: string
    dob: string
}

type ProfileFormProps = {
    defaultValues: ProfileFields
    onSubmit(data: ProfileFields): void
    isSubmitting: boolean
}

function ProfileForm({ defaultValues, onSubmit, isSubmitting }: ProfileFormProps) {
    const { register, control, handleSubmit, formState } = useForm<ProfileFields>({
        mode: 'onChange',
        defaultValues,
    })

    return (
        <form onSubmit={handleSubmit(onSubmit)}>
            <Input type="text" label="First name" {...register('firstName')} />
            <Input className="mt-2" type="text" label="Last name" {...register('lastName')} />
            <Controller
                control={control}
                name="dob"
                rules={{
                    validate: (d) =>
                        BrowserUtil.validateFormDate(d, {
                            minDate: DateTime.now().minus({ years: 100 }).toISODate(),
                            required: true,
                        }),
                }}
                render={({ field, fieldState: { error } }) => {
                    return (
                        <DatePicker
                            label="Date of birth"
                            popperPlacement="bottom"
                            className="mt-2"
                            error={error?.message}
                            {...field}
                        />
                    )
                }}
            />
            <Button className="mt-4" type="submit" disabled={!formState.isValid}>
                {isSubmitting && (
                    <LoadingIcon className="w-3 h-3 animate-spin text-gray inline mr-2 mb-0.5" />
                )}
                {isSubmitting ? 'Saving...' : 'Save changes'}
            </Button>
        </form>
    )
}

function MaybeCardSection() {
    const { useMemberCardDetails, useUpdateProfile } = useUserApi()

    const {
        register,
        handleSubmit,
        formState: { isSubmitting, isValid },
        watch,
        setValue,
    } = useForm<{
        title?: string
        maybe?: string
    }>({
        mode: 'onChange',
    })

    const title = watch('title')
    const maybe = watch('maybe')

    const updateProfile = useUpdateProfile({ onSuccess: undefined })

    const { data, isLoading } = useMemberCardDetails(undefined, {
        onSuccess: (data) => {
            if (!title)
                setValue('title', data.title ?? UserUtil.randomUserTitle(), {
                    shouldValidate: true,
                })
            if (!maybe)
                setValue('maybe', data.maybe ?? '', {
                    shouldValidate: true,
                })
        },
    })

    const [isCardFlipped, setIsCardFlipped] = useState(false)
    const [isShareModalOpen, setIsShareModalOpen] = useState(false)

    return (
        <form
            className="mt-5 text-base"
            onSubmit={handleSubmit((data) => updateProfile.mutate(data))}
        >
            <p className="text-gray-50 mb-2">Maybe Card</p>
            <div className="rounded-lg overflow-hidden">
                <MaybeCard variant="settings" flipped={isCardFlipped} details={data} />
                <MaybeCardShareModal
                    isOpen={isShareModalOpen}
                    onClose={() => setIsShareModalOpen(false)}
                    cardUrl={data?.cardUrl ?? ''}
                    card={{ details: data }}
                />
            </div>
            <div className="mt-6 w-full flex justify-center gap-3">
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
                            className={classNames(!data && 'opacity-50 pointer-events-none')}
                            href={data?.imageUrl}
                            download="maybe-card.png"
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

            <div className="relative mt-6">
                <label>
                    <span className="block mb-1 text-base text-gray-50 font-light leading-6">
                        Your Maybe
                    </span>
                    <textarea
                        rows={5}
                        className="block w-full bg-gray-500 text-base placeholder:text-gray-100 rounded border-0 focus:ring-0 resize-none"
                        placeholder="What's your Maybe?"
                        {...register('maybe', { required: true })}
                        onKeyDown={(e) => e.key === 'Enter' && e.stopPropagation()}
                        maxLength={UserUtil.MAX_MAYBE_LENGTH}
                        disabled={isLoading}
                    />
                    <div className="absolute bottom-0 right-0 flex items-center gap-1 px-3 py-2">
                        <FractionalCircle
                            radius={6}
                            percent={((maybe?.length ?? 0) / UserUtil.MAX_MAYBE_LENGTH) * 100}
                        />
                        <span className="text-sm text-gray-50">{240 - (maybe?.length ?? 0)}</span>
                    </div>
                </label>
            </div>
            <Button
                type="submit"
                variant="secondary"
                className="mt-6"
                disabled={!isValid || isSubmitting}
            >
                {updateProfile.isLoading && (
                    <LoadingIcon className="w-3 h-3 animate-spin text-gray inline mr-2 mb-0.5" />
                )}
                {updateProfile.isLoading ? 'Saving...' : 'Save changes'}
            </Button>
        </form>
    )
}
