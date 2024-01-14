import { signOut } from 'next-auth/react'
import { ProfileCircle } from '@maybe-finance/client/shared'
import { Button, Menu } from '@maybe-finance/design-system'
import type { SharedType } from '@maybe-finance/shared'
import classNames from 'classnames'
import uniqBy from 'lodash/uniqBy'
import upperFirst from 'lodash/upperFirst'
import { Fragment } from 'react'
import { RiArrowDownSLine, RiArrowLeftLine, RiCheckLine, RiShutDownLine } from 'react-icons/ri'

type Props = {
    steps: SharedType.OnboardingStep[]
    currentStep: SharedType.OnboardingStep
    onBack(): void
}

export function OnboardingNavbar({ steps, currentStep, onBack }: Props) {
    const groups = uniqBy(steps, 'group')
        .map((s) => s.group)
        .filter((g): g is string => g != null)
    const currentGroupSteps = steps.filter((step) => step.group === currentStep.group)
    const currentGroupIdx = groups.findIndex((group) => group === currentStep?.group)
    const isLastGroup = currentGroupIdx === groups.length - 1
    const hasSubsteps = currentGroupSteps.length > 1
    const substepIdx = currentGroupSteps.findIndex((substep) => substep.key === currentStep.key)

    return (
        <div className={classNames('mt-8 mx-4 md:mx-12', !hasSubsteps && 'mb-10 sm:mb-20')}>
            <div className="relative flex items-center justify-between">
                <div className="shrink-0 md:w-[148px]">
                    {isLastGroup ? (
                        <Button variant="icon" onClick={onBack}>
                            <RiArrowLeftLine size={24} />
                        </Button>
                    ) : (
                        <img src="/assets/maybe-full.svg" alt="Maybe" className="h-6" />
                    )}
                </div>
                <div className="hidden sm:flex items-center justify-center space-x-4 w-[468px] mx-10">
                    {groups.map((group, idx) => (
                        <Fragment key={idx}>
                            {idx > 0 && <div className="grow h-px bg-gray-500"></div>}
                            <div
                                className={classNames(
                                    'flex items-center gap-3 text-base',
                                    idx < currentGroupIdx
                                        ? 'text-teal'
                                        : idx === currentGroupIdx
                                        ? 'text-cyan'
                                        : 'text-white'
                                )}
                            >
                                <div
                                    className={classNames(
                                        'flex items-center justify-center w-6 h-6 rounded-md',
                                        idx < currentGroupIdx
                                            ? 'bg-teal bg-opacity-10'
                                            : idx === currentGroupIdx
                                            ? 'bg-cyan bg-opacity-10'
                                            : 'text-gray-100 bg-gray-700'
                                    )}
                                >
                                    {idx < currentGroupIdx ? (
                                        <RiCheckLine className="w-5 h-5" />
                                    ) : (
                                        idx + 1
                                    )}
                                </div>
                                {upperFirst(group)}
                            </div>
                        </Fragment>
                    ))}
                </div>
                <div className="shrink-0 md:w-[148px] flex items-center justify-end space-x-2">
                    <div className="shrink-0">
                        <ProfileCircle interactive={false} className="!w-10 !h-10" />
                    </div>
                    <Menu>
                        <Menu.Button variant="icon" type="button">
                            <RiArrowDownSLine className="w-6 h-6" />
                        </Menu.Button>
                        <Menu.Items placement="bottom-end">
                            <Menu.Item
                                icon={<RiShutDownLine />}
                                destructive={true}
                                onClick={() => signOut()}
                            >
                                Log out
                            </Menu.Item>
                        </Menu.Items>
                    </Menu>
                </div>
            </div>
            {currentGroupSteps.length > 1 && (
                <div className="flex justify-center items-center space-x-2 my-12 sm:my-16">
                    {currentGroupSteps.map((_, idx) => (
                        <div
                            key={idx}
                            className={classNames(
                                'w-6 h-1 rounded-full transition-colors',
                                idx === substepIdx ? 'bg-cyan' : 'bg-gray-500'
                            )}
                        ></div>
                    ))}
                </div>
            )}
        </div>
    )
}
