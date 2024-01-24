'use client'

import type { ReactElement } from 'react'
import { useRouter } from 'next/router'
import { WithSidebarLayout, AccountSidebar, NewPlanForm } from '@maybe-finance/client/features'
import { usePlanApi } from '@maybe-finance/client/shared'

export default function CreatePlanPage() {
    const { useCreatePlan } = usePlanApi()
    const createPlan = useCreatePlan()

    const router = useRouter()

    return (
        <div>
            <h3 className="mb-6">New plan</h3>
            <div className="max-w-sm">
                <NewPlanForm
                    initialValues={{
                        name: 'Retirement',
                        lifeExpectancy: 85,
                    }}
                    onSubmit={async (data) => {
                        const plan = await createPlan.mutateAsync(data)
                        router.push(`/plans/${plan.id}`)
                    }}
                />
            </div>
        </div>
    )
}

CreatePlanPage.getLayout = function getLayout(page: ReactElement) {
    return <WithSidebarLayout sidebar={<AccountSidebar />}>{page}</WithSidebarLayout>
}
