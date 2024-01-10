type SmallDecimalsProps = {
    value?: string
    className?: string
}

export const SmallDecimals = ({
    value = '',
    className = 'text-gray-100 text-2xl',
}: SmallDecimalsProps): JSX.Element => {
    const isValidValue = /(\.\d\d)$/.test(value)

    if (!isValidValue) {
        return (
            <>
                {value}
                <span></span>
            </>
        )
    }

    const [integer, decimal] = value.split('.')

    return (
        <>
            {integer}
            <span className={className} data-testid="decimals">
                .{decimal}
            </span>
        </>
    )
}

export default SmallDecimals
