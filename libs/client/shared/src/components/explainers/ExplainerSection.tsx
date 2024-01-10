import { forwardRef } from 'react'
import type { ReactNode, Ref } from 'react'
import classNames from 'classnames'

export type ExplainerSectionProps = {
    title: string | ReactNode
    children: ReactNode
    className?: string
}

function ExplainerSection(
    { title, children, className }: ExplainerSectionProps,
    ref: Ref<HTMLDivElement>
): JSX.Element {
    return (
        <div className="pt-1 pb-5 text-base" ref={ref}>
            <h6 className="font-display font-bold uppercase">{title}</h6>
            <div className={classNames('mt-2 text-gray-50', className)}>{children}</div>
        </div>
    )
}

export default forwardRef(ExplainerSection)
