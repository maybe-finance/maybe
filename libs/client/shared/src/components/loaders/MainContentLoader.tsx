import { LoadingSpinner } from '@maybe-finance/design-system'
import { Overlay } from '../overlays'

export interface MainContentLoaderProps {
    message?: string
}

export function MainContentLoader({ message }: MainContentLoaderProps) {
    return (
        <Overlay>
            <div className="absolute inset-0 flex flex-col items-center justify-center h-full transform -translate-y-16">
                <LoadingSpinner />
                {message && <p className="text-gray-50 text-base mt-2">{message}</p>}
            </div>
        </Overlay>
    )
}
