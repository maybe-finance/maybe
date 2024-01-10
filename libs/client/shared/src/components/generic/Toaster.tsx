import type { ToastVariant } from '@maybe-finance/design-system'
import { Toast } from '@maybe-finance/design-system'
import { Toaster as ReactToaster, resolveValue } from 'react-hot-toast'
import classNames from 'classnames'

const toastTypeMap: { [type: string]: ToastVariant } = Object.freeze({
    success: 'success',
    error: 'error',
})

export interface ToasterProps {
    mobile: boolean
    sidebarOffset?: string
}

export function Toaster({ mobile, sidebarOffset }: ToasterProps) {
    return (
        <ReactToaster
            position="bottom-center"
            toastOptions={{
                duration: 6000,
            }}
            containerClassName={classNames(mobile && 'mb-16')}
        >
            {(toastData) => (
                <Toast
                    variant={toastData.type in toastTypeMap ? toastTypeMap[toastData.type] : 'info'}
                    className={classNames(
                        'max-w-[320px] transition-opacity',
                        toastData.visible ? 'animate-appearUp' : 'opacity-0',
                        mobile ? 'w-full' : sidebarOffset
                    )}
                >
                    {resolveValue(toastData.message, toastData)}
                </Toast>
            )}
        </ReactToaster>
    )
}

export default Toaster
