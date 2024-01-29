'use client'

import { AccountSidebar, WithSidebarLayout } from '@maybe-finance/client/features'

export default function PagesWithSidebarLayout({ children }: { children: React.ReactNode }) {
    return <WithSidebarLayout sidebar={<AccountSidebar />}>{children}</WithSidebarLayout>
}
