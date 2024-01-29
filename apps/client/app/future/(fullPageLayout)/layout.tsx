'use client'

import { FullPageLayout } from '@maybe-finance/client/features'

export default function PagesWithFullPageLayout({ children }: { children: React.ReactNode }) {
    return <FullPageLayout>{children}</FullPageLayout>
}
