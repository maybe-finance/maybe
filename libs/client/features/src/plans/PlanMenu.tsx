import type { SharedType } from '@maybe-finance/shared'
import { DateUtil, PlanUtil } from '@maybe-finance/shared'

import { InsightPopout, usePlanApi, usePopoutContext } from '@maybe-finance/client/shared'
import { Button, Dialog, Menu } from '@maybe-finance/design-system'
import { RiArrowGoBackLine, RiBookReadLine } from 'react-icons/ri'
import { useState } from 'react'
import { usePlanContext } from './PlanContext'
import { PlanExplainer } from './PlanExplainer'

type Props = {
    plan?: SharedType.Plan
}

export function PlanMenu({ plan }: Props) {
    const [isOpen, setIsOpen] = useState(false)
    const { userAge } = usePlanContext()
    const { useUpdatePlanTemplate } = usePlanApi()

    const { open: openPopout } = usePopoutContext()

    const update = useUpdatePlanTemplate()

    if (!plan) return null

    return (
        <>
            <Menu>
                <Menu.Button variant="icon">
                    <i className="ri-more-2-fill text-white" />
                </Menu.Button>
                <Menu.Items placement="bottom-end">
                    <Menu.Item icon={<RiArrowGoBackLine />} onClick={() => setIsOpen(true)}>
                        Reset plan
                    </Menu.Item>
                    <Menu.Item
                        icon={<RiBookReadLine />}
                        onClick={() =>
                            openPopout(
                                <InsightPopout>
                                    <PlanExplainer />
                                </InsightPopout>
                            )
                        }
                    >
                        How this works
                    </Menu.Item>
                </Menu.Items>
            </Menu>
            <Dialog isOpen={isOpen} onClose={() => setIsOpen(false)} showCloseButton={false}>
                <Dialog.Content className="text-gray-50 text-base text-center">
                    <div className="flex items-center justify-center bg-cyan bg-opacity-10 w-12 h-12 rounded-lg transform -translate-y-4 mx-auto">
                        <RiArrowGoBackLine className="w-6 h-6 text-cyan" />
                    </div>
                    <h4 className="text-white mb-2">Reset plan?</h4>
                    <p className="mb-4">
                        By doing this you will be resetting any changes you have made to the plan so
                        far. You cannot undo this action.
                    </p>

                    <div className="flex items-center gap-4 mt-4">
                        <Button
                            className="w-2/4"
                            variant="secondary"
                            onClick={() => setIsOpen(false)}
                        >
                            Cancel
                        </Button>

                        <Button
                            className="w-2/4"
                            onClick={async () => {
                                /**
                                 * @todo - as we incorporate more plan templates, we should
                                 * be resetting to the current plan's template if possible
                                 * and only defaulting to retirement as the "default" template
                                 *
                                 * for now, we are assuming all plans use the retirement template
                                 */
                                await update.mutateAsync({
                                    id: plan.id,
                                    shouldReset: true,
                                    data: {
                                        type: 'retirement',
                                        data: {
                                            retirementYear: DateUtil.ageToYear(
                                                PlanUtil.RETIREMENT_MILESTONE_AGE,
                                                userAge ?? PlanUtil.DEFAULT_AGE
                                            ),
                                        },
                                    },
                                })

                                setIsOpen(false)
                            }}
                        >
                            Reset
                        </Button>
                    </div>
                </Dialog.Content>
            </Dialog>
        </>
    )
}
