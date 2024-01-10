import classNames from 'classnames'

const sizes = Object.freeze({
    md: {
        glow: 'blur-[6px]',
        outer: 'w-8 h-8',
    },
    xl: {
        glow: 'blur-[15px]',
        outer: 'w-20 h-20',
    },
})

type PremiumIconProps = React.HTMLAttributes<HTMLImageElement> & {
    size: keyof typeof sizes
    tilt?: boolean
    glow?: boolean
}

export function PremiumIcon({
    size,
    tilt = true,
    glow = true,
    className,
    ...rest
}: PremiumIconProps) {
    return (
        <div
            className={classNames(
                className,
                'relative',
                sizes[size].outer,
                tilt && 'rotate-[4deg]'
            )}
        >
            {glow && (
                <div
                    className={classNames(
                        'absolute block inset-0 opacity-60',
                        'bg-[linear-gradient(192deg,#52EDFF_9.79%,#4361EE_31.87%,#7209B7_60.44%,#F12980_90.2%)]',
                        sizes[size].glow
                    )}
                ></div>
            )}
            <img
                alt="Maybe"
                src="/assets/maybe-box.svg"
                className={'relative w-full h-full'}
                {...rest}
            />
        </div>
    )
}
