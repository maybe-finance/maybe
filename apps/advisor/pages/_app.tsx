import type { ComponentType, FC, ReactElement } from 'react'
import type { AppProps } from 'next/app'
import { type UserProfile, UserProvider } from '@auth0/nextjs-auth0/client'
import Meta from '../components/Meta'
import { trpc } from '../lib/trpc'
import './styles.css'
import type { SharedType } from '@maybe-finance/shared'
import Unauthorized from '../components/Unauthorized'
import Toaster from '../components/Toaster'

function App({
    Component,
    pageProps,
}: AppProps & {
    Component: AppProps['Component'] & {
        getLayout?: (component: ReactElement) => JSX.Element
    }
}) {
    const Page = withRoleAuthz(Component, {
        roles: ['Admin', 'Advisor'],
        user: pageProps.user,
        getLayout: Component.getLayout ?? ((page) => page),
    })

    return (
        <>
            <Meta />
            <Toaster />
            <UserProvider user={pageProps.user}>{<Page {...pageProps} />}</UserProvider>
        </>
    )
}

export default trpc.withTRPC(App)

const withRoleAuthz = <P extends object>(
    Page: ComponentType<P>,
    opts: {
        roles: SharedType.UserRole[]
        getLayout(component: ReactElement): JSX.Element
        user?: UserProfile
    }
): FC<P> => {
    return function hoc(props) {
        const userRoles = (opts.user?.['https://maybe.co/roles'] ?? []) as SharedType.UserRole[]
        const match = opts.roles.some((role) => userRoles.includes(role))

        if (match) {
            return opts.getLayout(<Page {...props} />)
        } else {
            return <Unauthorized />
        }
    }
}
