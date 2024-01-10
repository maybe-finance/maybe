import { Disclosure } from '@headlessui/react'
import { Button } from '@maybe-finance/design-system'
import classNames from 'classnames'

type AccountGroupProps = {
    title: string
    subtitle: React.ReactNode
    content: React.ReactNode
    menu?: React.ReactNode
    footer?: React.ReactNode
}

export function AccountGroup({ title, subtitle, content, menu, footer }: AccountGroupProps) {
    return (
        <Disclosure
            as="li"
            className="p-4 rounded-lg bg-gray-800 list-none"
            data-testid="account-group"
        >
            {({ open }) => (
                <>
                    <div className="flex items-center justify-between">
                        <div className="text-base">
                            <p className="text-white">{title}</p>
                            <p className="text-gray-100">{subtitle}</p>
                        </div>
                        <div className="flex items-center space-x-1">
                            {menu}
                            <Disclosure.Button
                                as={Button}
                                variant="icon"
                                className={classNames(open && 'rotate-180')}
                            >
                                <i className="ri-arrow-down-s-line text-white" />
                            </Disclosure.Button>
                        </div>
                    </div>

                    <Disclosure.Panel>
                        <div className="mt-4 bg-gray-700 rounded-lg">{content}</div>
                        <div className={classNames(!!footer && 'mt-4')}>{footer}</div>
                    </Disclosure.Panel>
                </>
            )}
        </Disclosure>
    )
}
