import type { ReactNode, HTMLAttributes } from 'react'
import { Fragment } from 'react'
import classNames from 'classnames'
import { RiArrowRightSLine } from 'react-icons/ri'
import Link from 'next/link'

export interface BreadcrumbProps {
    href?: string
    className?: string
    children: ReactNode
}

function Breadcrumb({ href, className, children }: BreadcrumbProps): JSX.Element {
    const Tag = href ? 'a' : 'span'
    const inner = <Tag className={classNames('', className)}>{children}</Tag>

    return href ? (
        <Link href={href} legacyBehavior>
            {inner}
        </Link>
    ) : (
        inner
    )
}

export interface BreadcrumbGroupProps extends HTMLAttributes<HTMLDivElement> {
    className?: string
    children: ReactNode[]
}

function Group({ className, children, ...rest }: BreadcrumbGroupProps): JSX.Element {
    return (
        <div
            className={classNames('flex items-center space-x-1 text-gray-100 text-base', className)}
            {...rest}
        >
            {children.map((child, idx) => (
                <Fragment key={`${child}-${idx}`}>
                    <span className={classNames(idx === children.length - 1 && 'text-white')}>
                        {child}
                    </span>
                    {idx < children.length - 1 && <RiArrowRightSLine className="w-4 h-4" />}
                </Fragment>
            ))}
        </div>
    )
}

export default Object.assign(Breadcrumb, { Group })
