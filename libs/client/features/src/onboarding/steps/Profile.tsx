import {
    Button,
    Checkbox,
    DatePicker,
    Listbox,
    LoadingSpinner,
    Tooltip,
} from '@maybe-finance/design-system'
import classNames from 'classnames'
import { DateTime } from 'luxon'
import { type PropsWithChildren, type ReactNode, useState, useEffect, useCallback } from 'react'
import AnimateHeight from 'react-animate-height'
import { Controller, useForm, useFormState } from 'react-hook-form'
import type { IconType } from 'react-icons'
import {
    RiArrowDownSLine,
    RiArrowUpSLine,
    RiCakeLine,
    RiCheckLine,
    RiFlagLine,
    RiFocus2Line,
    RiFolder2Line,
    RiHome5Line,
    RiMapPin2Line,
    RiQuestionLine,
} from 'react-icons/ri'
import { AiOutlineLoading3Quarters as LoadingIcon } from 'react-icons/ai'
import type { StepProps } from './StepProps'
import { Switch } from '@headlessui/react'
import { BrowserUtil, useUserApi } from '@maybe-finance/client/shared'
import type { Household, MaybeGoal } from '@prisma/client'
import { DateUtil, Geo } from '@maybe-finance/shared'

type FormValues = {
    dob: string | null
    household: Household | null
    country: string
    state: string
    maybeGoals?: MaybeGoal[]
    maybeGoalsDescription?: string
}

function getDateFormatByCountryCode(countryCode: string): string {
    const country = Geo.countries.filter((country) => country.code === countryCode)
    if (country.length > 0) {
        return country[0].dateFormat
    }

    return 'dd / MM / yyyy'
}

export function Profile({ title, onNext }: StepProps) {
    const { useUpdateProfile, useProfile } = useUserApi()
    const updateProfile = useUpdateProfile({ onSuccess: undefined })

    const profile = useProfile({})

    if (profile.isError) {
        return <p>Something went wrong</p>
    }

    if (profile.isLoading) {
        return <LoadingSpinner />
    }

    const user = profile.data

    return (
        <ProfileForm
            title={title}
            defaultValues={{
                dob: DateUtil.dateTransform(user.dob),
                household: user.household,
                country: user.country ?? '',
                state: user.state ?? '',
                maybeGoals: user.maybeGoals ?? [],
                maybeGoalsDescription: user.maybeGoalsDescription ?? '',
            }}
            onSubmit={async (data) => {
                await updateProfile.mutateAsync({
                    dob: data.dob,
                    household: data.household,
                    country: data.country,
                    state: null, // should always be null for now
                    maybeGoals: data.maybeGoals,
                    maybeGoalsDescription: data.maybeGoalsDescription,
                })

                await onNext()
            }}
        />
    )
}

type ProfileViewProps = {
    title: string
    onSubmit(data: FormValues): void
    defaultValues: FormValues
}

function ProfileForm({ title, onSubmit, defaultValues }: ProfileViewProps) {
    const [currentQuestion, setCurrentQuestion] = useState<
        'birthday' | 'household' | 'residence' | 'goals'
    >('residence')

    const {
        control,
        register,
        handleSubmit,
        trigger,
        watch,
        formState: { isValid, isSubmitting },
    } = useForm<FormValues>({
        mode: 'onChange',
        defaultValues,
    })

    const country = watch('country')

    useEffect(() => {
        trigger()
    }, [currentQuestion, trigger])

    const { errors } = useFormState({ control })

    return (
        <div className="w-full max-w-md mx-auto">
            <h3 className="text-center">{title}</h3>
            <p className="mt-4 text-base text-gray-50">
                We&rsquo;ll need a few things from you to offer a personal experience when it comes
                to building plans or receiving advice from our advisors.
            </p>
            <div className="mt-5 space-y-3">
                <Question
                    open={currentQuestion === 'residence'}
                    valid={!errors.country}
                    icon={RiMapPin2Line}
                    label="Where are you based?"
                    onClick={() => setCurrentQuestion('residence')}
                    next={() => setCurrentQuestion('birthday')}
                >
                    <div className="space-y-2">
                        <Controller
                            name="country"
                            rules={{ required: true }}
                            defaultValue="US"
                            control={control}
                            render={({ field }) => (
                                <Listbox {...field}>
                                    <Listbox.Button label="Country">
                                        {Geo.countries.find((c) => c.code === field.value)?.name ||
                                            'Select'}
                                    </Listbox.Button>
                                    <Listbox.Options className="max-h-[300px] custom-gray-scroll">
                                        {Geo.countries.map((country) => (
                                            <Listbox.Option key={country.code} value={country.code}>
                                                {country.name}
                                            </Listbox.Option>
                                        ))}
                                    </Listbox.Options>
                                </Listbox>
                            )}
                        />
                    </div>
                    <Tooltip
                        placement="bottom-start"
                        content={
                            <>
                                We use your location to provide accurate advice and ensure
                                regulatory compliance.
                            </>
                        }
                    >
                        <div className="flex items-center mt-4 text-base text-gray-50 cursor-default">
                            <RiQuestionLine className="w-5 h-5 mr-2 text-gray-100" />
                            Why do we need your location?
                        </div>
                    </Tooltip>
                </Question>
                <Question
                    open={currentQuestion === 'birthday'}
                    valid={!errors.dob}
                    icon={RiCakeLine}
                    label={<>When&rsquo;s your birthday?</>}
                    onClick={() => setCurrentQuestion('birthday')}
                    next={() => setCurrentQuestion('household')}
                    back={() => setCurrentQuestion('residence')}
                >
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
                        render={({ field, fieldState: { error } }) => (
                            <DatePicker
                                popperPlacement="bottom"
                                className="mt-2"
                                minCalendarDate={DateTime.now().minus({ years: 100 }).toISODate()}
                                error={error?.message}
                                placeholder={getDateFormatByCountryCode(country).toUpperCase()}
                                dateFormat={getDateFormatByCountryCode(country)}
                                {...field}
                            />
                        )}
                    />
                    <Tooltip
                        placement="bottom-start"
                        content={
                            <>
                                We use your age to personalize plans to your context instead of
                                showing years when referring to future events. &ldquo;Retire at
                                45&rdquo; sounds better than &ldquo;Retire in 2043&rdquo;.
                            </>
                        }
                    >
                        <div className="flex items-center mt-4 text-base text-gray-50 cursor-default">
                            <RiQuestionLine className="w-5 h-5 mr-2 text-gray-100" />
                            Why do we need your age?
                        </div>
                    </Tooltip>
                </Question>

                <Question
                    open={currentQuestion === 'household'}
                    valid={!errors.household}
                    icon={RiHome5Line}
                    label="Which best describes your household?"
                    onClick={() => setCurrentQuestion('household')}
                    back={() => setCurrentQuestion('birthday')}
                    next={() => setCurrentQuestion('goals')}
                >
                    <div className="space-y-2">
                        <Controller
                            control={control}
                            name="household"
                            rules={{ required: true }}
                            render={({ field }) => (
                                <>
                                    {Object.entries({
                                        single: 'Single income, no dependents',
                                        singleWithDependents:
                                            'Single income, at least one dependent',
                                        dual: 'Dual income, no dependents',
                                        dualWithDependents: 'Dual income, at least one dependent',
                                        retired: 'Retired or financially independent',
                                    }).map(([value, label]) => (
                                        <Checkbox
                                            key={value}
                                            label={label}
                                            checked={field.value === value}
                                            onChange={(checked) => {
                                                if (checked) field.onChange(value)
                                            }}
                                        />
                                    ))}
                                </>
                            )}
                        />
                    </div>
                </Question>

                <Question
                    open={currentQuestion === 'goals'}
                    icon={RiFocus2Line}
                    label="What do you hope to achieve with Maybe?"
                    onClick={() => setCurrentQuestion('goals')}
                    back={() => setCurrentQuestion('residence')}
                    submit={handleSubmit(onSubmit)}
                    valid={isValid}
                    loading={isSubmitting}
                >
                    <Controller
                        control={control}
                        name="maybeGoals"
                        render={({ field }) => (
                            <div className="flex flex-col space-y-2">
                                {Object.entries({
                                    aggregate: [RiFolder2Line, 'See all my accounts in one place'],
                                    plan: [
                                        RiFlagLine,
                                        'Build plans for retirement and other milestones',
                                    ],
                                }).map(([value, [Icon, label]]) => {
                                    const checked = field.value?.includes(value as MaybeGoal)
                                    return (
                                        <Switch
                                            key={value}
                                            className={classNames(
                                                'flex items-center p-3 text-base rounded-xl border transition-colors duration-100',
                                                checked
                                                    ? 'bg-gray-600 bg-opacity-50 border-cyan'
                                                    : 'backdrop-blur-sm border-gray-100 border-opacity-10'
                                            )}
                                            checked={checked}
                                            onChange={(check: boolean) => {
                                                if (check && !checked)
                                                    field.onChange([
                                                        ...(field.value ? field.value : []),
                                                        value,
                                                    ])
                                                else if (!check && checked)
                                                    field.onChange(
                                                        field.value!.filter((v) => v !== value)
                                                    )
                                            }}
                                        >
                                            <>
                                                <Icon
                                                    className={classNames(
                                                        'w-6 h-6 mr-3',
                                                        checked ? 'text-cyan' : 'text-gray-100'
                                                    )}
                                                />
                                                {label}
                                                {checked && (
                                                    <div className="grow flex justify-end">
                                                        <div className="p-0.5 bg-cyan rounded-full">
                                                            <RiCheckLine className="w-3 h-3 text-black" />
                                                        </div>
                                                    </div>
                                                )}
                                            </>
                                        </Switch>
                                    )
                                })}
                            </div>
                        )}
                    />

                    <label className="block mt-3">
                        <span className="text-base text-gray-50">Other</span>
                        <textarea
                            rows={4}
                            className="block w-full bg-gray-500 text-base placeholder:text-gray-100 rounded border-0 focus:ring-0 resize-none"
                            placeholder="Enter any other things you'd like to do with Maybe"
                            {...register('maybeGoalsDescription')}
                            onKeyDown={(e) => e.key === 'Enter' && e.stopPropagation()}
                        />
                    </label>
                </Question>
            </div>
        </div>
    )
}

function Question({
    open,
    valid = false,
    icon: Icon,
    label,
    onClick,
    back,
    next,
    submit,
    loading = false,
    children,
}: PropsWithChildren<{
    open: boolean
    valid?: boolean
    icon: IconType
    label: ReactNode
    onClick: () => void
    back?: () => void
    next?: () => void
    submit?: () => void
    loading?: boolean
}>) {
    const keyDown = useCallback(
        (e: KeyboardEvent) => {
            if (!open) return

            switch (e.key) {
                case 'Enter':
                    if (next) next()
                    else if (submit) submit()
                    break
                case '\\':
                    if (back) back()
                    break
            }
        },
        [open, back, next, submit]
    )

    useEffect(() => {
        document.addEventListener('keydown', keyDown)
        return () => document.removeEventListener('keydown', keyDown)
    }, [keyDown])

    return (
        <div>
            <button
                className="w-full group flex items-center p-3 -mx-3 rounded-xl hover:bg-gray-100/5 transition-colors duration-75"
                type="button"
                onClick={onClick}
            >
                <Icon
                    className={classNames(
                        'w-5 h-5 transition-colors duration-75',
                        open ? 'text-gray-100' : 'text-gray-300 group-hover:text-gray-200'
                    )}
                />
                <span
                    className={classNames(
                        'ml-2 text-base transition-colors duration-75',
                        open ? 'text-gray-25' : 'text-gray-200 group-hover:text-gray-100'
                    )}
                >
                    {label}
                </span>
            </button>
            <AnimateHeight height={open ? 'auto' : 0} duration={150}>
                <div className="mt-3">{children}</div>
                {(next || back || submit) && (
                    <div className="flex items-center justify-between mt-3">
                        <span className="invisible sm:visible flex items-center space-x-3 text-sm text-gray-100">
                            {back && (
                                <div className="flex items-center">
                                    <span className="mr-2 py-0.5 px-1 bg-gray-700 rounded-sm text-white">
                                        \
                                    </span>
                                    Back
                                </div>
                            )}
                            {(next || submit) && valid && (
                                <div className="flex items-center">
                                    <span className="mr-2 py-0.5 px-1 bg-gray-700 rounded-sm text-white">
                                        Enter &#x23CE;
                                    </span>
                                    {submit ? 'Finish' : 'Next'}
                                </div>
                            )}
                        </span>
                        <div className="flex items-center space-x-3">
                            {back && (
                                <Button onClick={back} variant="secondary">
                                    {submit ? 'Back' : <RiArrowUpSLine className="w-5 h-5" />}
                                </Button>
                            )}
                            {next && (
                                <Button onClick={next} disabled={!valid}>
                                    <RiArrowDownSLine className="w-5 h-5" />
                                </Button>
                            )}
                            {submit && (
                                <Button onClick={submit} disabled={!valid}>
                                    {loading ? (
                                        <LoadingIcon className="w-6 h-6 p-1 mx-2 text-gray animate-spin" />
                                    ) : (
                                        'Finish'
                                    )}
                                </Button>
                            )}
                        </div>
                    </div>
                )}
            </AnimateHeight>
        </div>
    )
}
