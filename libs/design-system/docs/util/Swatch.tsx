import classNames from 'classnames'
import React from 'react'

export interface SwatchProps {
    color: string
    className: string
}

function Swatch({ color, className }: SwatchProps): JSX.Element {
    return (
        <div className="inline-block mr-4 mb-6" title={className}>
            <div className={classNames('rounded-lg w-32 h-12', className)}></div>
            <span className="text-sm text-white">{color}</span>
        </div>
    )
}

export default Swatch
