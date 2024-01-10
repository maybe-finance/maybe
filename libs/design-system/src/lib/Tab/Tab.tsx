import type { PropsWithChildren } from 'react'
import { Tab as HeadlessTab } from '@headlessui/react'
import classNames from 'classnames'

type ExtractProps<T> = T extends React.ComponentType<infer P> ? P : T

function Tab({
    className,
    children,
    icon,
    ...rest
}: { icon?: React.ReactNode } & PropsWithChildren<ExtractProps<typeof HeadlessTab>>): JSX.Element {
    return (
        <HeadlessTab
            className={({ selected }) =>
                classNames(
                    className,
                    'grow flex items-center justify-center text-base py-1 px-4 rounded focus:outline-none focus:ring-2 focus:ring-opacity-60',
                    'focus:ring-gray-400',
                    selected
                        ? 'bg-gray-400 hover:bg-gray-300 text-white shadow'
                        : 'hover:bg-gray-600 text-gray-100'
                )
            }
            {...(rest as any)}
        >
            {icon && <span className={classNames('text-lg', children && 'mr-2')}>{icon}</span>}
            {children}
        </HeadlessTab>
    )
}

function Group(props: ExtractProps<typeof HeadlessTab.Group>): JSX.Element {
    return <HeadlessTab.Group {...props} />
}

function List({ className, ...rest }: ExtractProps<typeof HeadlessTab.List>): JSX.Element {
    return (
        <HeadlessTab.List
            className={classNames(
                className,
                'inline-flex items-center space-x-1 p-1 rounded-lg bg-gray-700 text-white'
            )}
            {...rest}
        />
    )
}

function Panels({ className, ...rest }: ExtractProps<typeof HeadlessTab.Panels>): JSX.Element {
    return <HeadlessTab.Panels className={classNames(className)} {...rest} />
}

function Panel({ className, ...rest }: ExtractProps<typeof HeadlessTab.Panel>): JSX.Element {
    return <HeadlessTab.Panel className={classNames(className, 'focus:outline-none')} {...rest} />
}

export default Object.assign(Tab, { Group, List, Panels, Panel })
