import type { PropsWithChildren } from 'react'
import { motion } from 'framer-motion'
import type { IconType } from 'react-icons'
import { Overlay } from './Overlay'
import classNames from 'classnames'

export type BlurredContentOverlayProps = PropsWithChildren<{
    title: string
    icon?: IconType
    className?: string
}>

export function BlurredContentOverlay({
    title,
    icon: Icon,
    children,
    className,
}: BlurredContentOverlayProps) {
    return (
        <Overlay>
            <div
                className={classNames(
                    'absolute -inset-2 flex flex-col pt-48 lg:pt-72 items-center bg-black bg-opacity-10 backdrop-blur-sm',
                    className
                )}
            >
                <motion.div
                    key={title}
                    initial={{ opacity: 0.5, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    className="max-w-sm flex flex-col items-center p-6 bg-gray-700 rounded"
                >
                    {Icon && (
                        <div className="mb-4 p-3 bg-cyan bg-opacity-10 rounded-xl">
                            <Icon className="w-6 h-6 text-cyan" />
                        </div>
                    )}
                    <h4 className="text-center">{title}</h4>
                    <div className="mt-2 text-base text-gray-100 text-center">{children}</div>
                </motion.div>
            </div>
        </Overlay>
    )
}
