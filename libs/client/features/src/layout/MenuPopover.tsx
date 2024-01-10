import { useAuth0 } from '@auth0/auth0-react'
import { Menu } from '@maybe-finance/design-system'
import type { ComponentProps } from 'react'
import {
    RiSettings3Line as SettingsIcon,
    RiShutDownLine as LogoutIcon,
    RiDatabase2Line,
} from 'react-icons/ri'

export function MenuPopover({
    icon,
    placement = 'top-end',
    isHeader,
}: {
    icon: JSX.Element
    placement?: ComponentProps<typeof Menu.Item>['placement']
    isHeader: boolean
}) {
    const { logout } = useAuth0()

    return (
        <Menu>
            <Menu.Button variant="icon">{icon}</Menu.Button>
            <Menu.Items
                placement={placement}
                className={isHeader ? 'bg-gray-600' : 'min-w-[200px]'}
            >
                <Menu.ItemNextLink icon={<SettingsIcon />} href="/settings">
                    Settings
                </Menu.ItemNextLink>
                <Menu.ItemNextLink icon={<RiDatabase2Line />} href="/data-editor">
                    Fix my data
                </Menu.ItemNextLink>
                <Menu.Item
                    icon={<LogoutIcon />}
                    destructive={true}
                    onClick={() => logout({ logoutParams: { returnTo: window.location.origin } })}
                >
                    Log out
                </Menu.Item>
            </Menu.Items>
        </Menu>
    )
}
