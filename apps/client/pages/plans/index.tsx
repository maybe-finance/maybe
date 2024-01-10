import type { ReactElement } from 'react'
import { useEffect } from 'react'

import { WithSidebarLayout, AccountSidebar } from '@maybe-finance/client/features'
import { LoadingSpinner } from '@maybe-finance/design-system'
import { usePlanApi } from '@maybe-finance/client/shared'
import { useRouter } from 'next/router'

export default function PlansPage() {
    const { usePlans } = usePlanApi()
    const plans = usePlans()

    const router = useRouter()

    useEffect(() => {
        if (plans.data) {
            router.push(`/plans/${plans.data.plans[0].id}`)
        }
    }, [plans.data, router])

    if (plans.isLoading) {
        return (
            <div className="absolute inset-0 flex items-center justify-center h-full">
                <LoadingSpinner />
            </div>
        )
    }

    /** @todo add back UI when users are able to manage plans */
    return (
        <></>
        // <div className="h-full flex flex-col items-center justify-center">
        //     <h4 className="mb-2">No plans yet</h4>
        //     <div className="text-base text-gray-100 max-w-sm text-center mb-4">
        //         There are no plans yet. Start by creating a new one or start with sample data to get
        //         a preview.
        //     </div>
        //     <div className="flex space-x-3">
        //         <Link href="/plans/sample">
        //             <Button as="a" variant="secondary">
        //                 Use sample data
        //             </Button>
        //         </Link>
        //         <Link href="/plans/create">
        //             <Button as="a" leftIcon={<RiAddLine className="w-5 h-5" />}>
        //                 Create new plan
        //             </Button>
        //         </Link>
        //     </div>
        // </div>
    )
}

PlansPage.getLayout = function getLayout(page: ReactElement) {
    return <WithSidebarLayout sidebar={<AccountSidebar />}>{page}</WithSidebarLayout>
}
