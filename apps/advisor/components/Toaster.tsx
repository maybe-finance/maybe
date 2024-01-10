import { Toaster as RHToaster, resolveValue } from 'react-hot-toast'
import cn from 'classnames'
import { Toast } from '@maybe-finance/design-system'

type Props = {
    className?: string
}

export default function Toaster({ className }: Props) {
    return (
        <RHToaster>
            {(t) => (
                <Toast
                    variant={t.type as any}
                    className={cn(
                        'max-w-[320px] transition-opacity',
                        t.visible ? 'animate-appearUp' : 'opacity-0',
                        className
                    )}
                >
                    {resolveValue(t.message, t)}
                </Toast>
            )}
        </RHToaster>
    )
}
