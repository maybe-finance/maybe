import classNames from 'classnames'

export type PlanSelectorProps = {
    selected: 'monthly' | 'yearly'
    onChange: (selected: 'monthly' | 'yearly') => void
    className?: string
}

export function PlanSelector({ selected, onChange, className }: PlanSelectorProps) {
    return (
        <div
            className={classNames(
                className,
                'flex flex-wrap space-y-4 sm:flex-nowrap sm:space-x-6 sm:space-y-0'
            )}
        >
            <PlanOption
                name="Annual"
                bonus="Save $79"
                price="$149"
                period="year"
                subtext="$12.42/month billed yearly"
                active={selected === 'yearly'}
                onClick={() => onChange('yearly')}
            />
            <PlanOption
                name="Monthly"
                price="$19"
                period="month"
                subtext="$228/year billed monthly"
                active={selected === 'monthly'}
                onClick={() => onChange('monthly')}
            />
        </div>
    )
}

function PlanOption({
    name,
    bonus,
    price,
    period,
    subtext,
    onClick,
    active,
}: {
    name: string
    bonus?: string
    price: string
    period: string
    subtext: string
    onClick: () => void
    active: boolean
}) {
    return (
        <button
            className={classNames(
                'block w-full p-4 text-left text-base rounded-xl border transition-colors duration-50 cursor-pointer outline-none',
                active ? 'border-cyan bg-gray-600' : 'border-gray-500 hover:bg-gray-700'
            )}
            onClick={onClick}
        >
            <div className="flex items-start">
                <div className="pr-2 text-gray-100 grow">{name}</div>
                {bonus && (
                    <div
                        className={classNames(
                            'shrink-0 flex items-center space-x-2.5 -mr-2 -mt-2 py-1 px-2 rounded-lg font-medium text-sm leading-4',
                            active ? 'text-black bg-cyan' : 'text-white bg-gray-500',
                            bonus && 'pr-1.5'
                        )}
                    >
                        {bonus}
                    </div>
                )}
            </div>
            <div className="mt-1 text-lg font-bold text-white font-display">
                <span className="text-3xl">{price}</span>/{period}
            </div>
            <div className="text-gray-100">{subtext}</div>
        </button>
    )
}
