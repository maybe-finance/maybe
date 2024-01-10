import type { AnchorHTMLAttributes } from 'react'
import type { StepProps } from '../StepProps'
import { Controller, useForm } from 'react-hook-form'
import { Button, Checkbox, LoadingSpinner } from '@maybe-finance/design-system'
import { BrowserUtil, useUserApi } from '@maybe-finance/client/shared'
import keyBy from 'lodash/keyBy'
import type { AgreementType } from '@prisma/client'
import type { SharedType } from '@maybe-finance/shared'
import classNames from 'classnames'
import { AiOutlineLoading3Quarters } from 'react-icons/ai'

export function Terms({ title, onNext }: StepProps) {
    const {
        control,
        handleSubmit,
        formState: { isValid, isSubmitting },
    } = useForm<{ agree: boolean }>({
        mode: 'onChange',
    })

    const { useSignAgreements, useNewestAgreements } = useUserApi()

    const newestAgreements = useNewestAgreements('public')
    const signAgreements = useSignAgreements()

    if (newestAgreements.error) {
        return (
            <div className="flex flex-col text-center items-center justify-center max-w-screen-md mx-auto">
                <h3>Something went wrong.</h3>
                <p className="text-gray-50">
                    We were unable to load the advisory agreements and cannot continue without
                    these. Please contact us and we will get this fixed ASAP!
                </p>
            </div>
        )
    }

    if (newestAgreements.isLoading) {
        return (
            <div className="flex justify-center">
                <LoadingSpinner />
            </div>
        )
    }

    const { fee, form_crs, form_adv_2a, form_adv_2b, privacy_policy } = keyBy(
        newestAgreements.data,
        'type'
    ) as Record<AgreementType, SharedType.AgreementWithUrl>

    return (
        <form
            className="w-full max-w-[464px] mx-auto"
            onSubmit={handleSubmit(async (data) => {
                if (!data.agree) throw new Error('User must accept agreement to continue')
                if (!newestAgreements.data) throw new Error('Unable to sign agreements')

                await signAgreements.mutateAsync(newestAgreements.data.map((a) => a.id))
                await onNext()
            })}
        >
            <h3 className="text-center">{title}</h3>
            <div className="text-base text-gray-50">
                <p className="mt-4">
                    Please have a look at the documents linked below and agree to the following
                    terms.
                </p>
                <div className="mt-4">
                    <Controller
                        control={control}
                        name="agree"
                        rules={{ required: true }}
                        render={({ field }) => (
                            <Checkbox
                                checked={field.value}
                                onChange={(checked) => field.onChange(checked)}
                                wrapperClassName="!items-start mt-2"
                                label={
                                    <div className="-mt-1">
                                        By checking this box you:
                                        <ul
                                            className="list-disc list-outside ml-[1.5em]"
                                            onClick={(e) => e.stopPropagation()}
                                        >
                                            <li>
                                                Agree to our{' '}
                                                <ExternalLink href={fee.url}>
                                                    {BrowserUtil.agreementName('fee')}
                                                </ExternalLink>
                                                <p className="text-gray-100 italic">
                                                    This is an agreement that memorializes our
                                                    advisory relationship, describes our services
                                                    and fees, and explains our various rights and
                                                    responsibilities.
                                                </p>
                                            </li>
                                            <li>
                                                Consent to electronic delivery of communications
                                            </li>
                                            <li>
                                                Acknowledge you have received a copy of:
                                                <ul className="list-disc list-outside ml-[1.5em]">
                                                    <li>
                                                        <ExternalLink href={form_crs.url}>
                                                            {BrowserUtil.agreementName('form_crs')}
                                                        </ExternalLink>
                                                        <p className="text-gray-100 italic">
                                                            Also known as the "Relationship
                                                            Summary", this is a two-page summary of
                                                            our services, compensation, conflicts of
                                                            interest, and any applicable legal or
                                                            disciplinary history.
                                                        </p>
                                                    </li>
                                                    <li>
                                                        <ExternalLink href={form_adv_2a.url}>
                                                            {BrowserUtil.agreementName(
                                                                'form_adv_2a'
                                                            )}
                                                        </ExternalLink>
                                                        <p className="text-gray-100 italic">
                                                            Also referred to as the "Brochure", this
                                                            is a narrative brochure about our firm.
                                                        </p>
                                                    </li>
                                                    <li>
                                                        <ExternalLink href={form_adv_2b.url}>
                                                            {BrowserUtil.agreementName(
                                                                'form_adv_2b'
                                                            )}
                                                        </ExternalLink>
                                                        <p className="text-gray-100 italic">
                                                            Also referred to as the "Brochure
                                                            Supplement", this is a narrative
                                                            brochure about our investment
                                                            professionals.
                                                        </p>
                                                    </li>
                                                    <li>
                                                        <ExternalLink href={privacy_policy.url}>
                                                            {BrowserUtil.agreementName(
                                                                'privacy_policy'
                                                            )}
                                                        </ExternalLink>
                                                        <p className="text-gray-100 italic">
                                                            Explains how we safeguard your
                                                            information and data.
                                                        </p>
                                                    </li>
                                                </ul>
                                            </li>
                                        </ul>
                                    </div>
                                }
                            />
                        )}
                    />
                </div>
            </div>
            <Button
                type="submit"
                className={classNames('mt-5', isSubmitting && 'animate-pulse')}
                fullWidth
                disabled={!isValid}
            >
                Continue
                {isSubmitting && (
                    <AiOutlineLoading3Quarters className="ml-2 w-5 h-5 animate-spin" />
                )}
            </Button>
        </form>
    )
}

function ExternalLink({ children, ...rest }: AnchorHTMLAttributes<HTMLAnchorElement>): JSX.Element {
    return (
        <a rel="noreferrer" target="_blank" className="text-cyan underline" {...rest}>
            {children}
        </a>
    )
}
