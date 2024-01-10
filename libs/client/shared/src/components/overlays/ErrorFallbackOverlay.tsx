import type { FallbackProps } from 'react-error-boundary'
import { Button } from '@maybe-finance/design-system'
import { Overlay } from './Overlay'

export function ErrorFallback({ resetErrorBoundary: _ }: FallbackProps) {
    return (
        <Overlay>
            <div
                role="alert"
                className="absolute inset-0 py-10 flex items-center transform -translate-y-24"
            >
                <div className="p-4 xs:p-6 tracking-wide flex items-center justify-center space-y-4 flex-col mx-auto max-w-md">
                    <img src="/assets/maybe.svg" alt="Maybe Finance Logo" height={96} width={96} />
                    <p>Oops! Something went wrong.</p>
                    <Button onClick={() => window.location.reload()}>Try Again</Button>
                </div>
            </div>
        </Overlay>
    )
}
