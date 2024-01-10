import { RadioGroup as HeadlessRadio } from '@headlessui/react'
import classNames from 'classnames'
import type { PropsWithChildren } from 'react'

type ExtractProps<T> = T extends React.ComponentType<infer P> ? P : T

function RadioGroup(props: ExtractProps<typeof HeadlessRadio>) {
    return <HeadlessRadio {...props} />
}

function RadioOption({
    children,
    ...rest
}: PropsWithChildren<ExtractProps<typeof HeadlessRadio.Option>>) {
    return (
        <HeadlessRadio.Option {...rest}>
            {({ checked }) => (
                <div className="flex items-center gap-2">
                    {/* Circle centered inside a circle */}
                    <span
                        className={classNames(
                            'relative inline-block w-4 h-4 rounded-full border',
                            checked ? 'border-cyan' : 'border-gray-300'
                        )}
                    >
                        <span
                            className={classNames(
                                'absolute w-[10px] h-[10px] top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 rounded-full z-10',
                                checked ? 'bg-cyan' : 'bg-transparent'
                            )}
                        />
                    </span>
                    {children}
                </div>
            )}
        </HeadlessRadio.Option>
    )
}

export default Object.assign(RadioGroup, { Label: HeadlessRadio.Label, Option: RadioOption })
