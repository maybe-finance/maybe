import type { ReactNode } from 'react'
import classNames from 'classnames'

export interface FormGroupProps {
    className?: string
    children?: ReactNode
}

function FormGroup({ className, children, ...rest }: FormGroupProps): JSX.Element {
    const combinedClassName = classNames(className, 'mb-4')

    return (
        <div className={combinedClassName} {...rest}>
            {children}
        </div>
    )
}

export default FormGroup
