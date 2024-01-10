import { type MouseEvent, type CSSProperties, useRef, useEffect } from 'react'
import { animate, motion, useMotionValue, useTransform } from 'framer-motion'
import { DateTime } from 'luxon'
import classNames from 'classnames'
import type { SharedType } from '@maybe-finance/shared'
import { LoadingSpinner } from '@maybe-finance/design-system'

const MaybeCardVariants = {
    default: 'w-full h-full flex items-center justify-center',
    onboarding: 'p-8',
    settings: 'py-12 w-full flex items-center justify-center bg-gray-800',
}

export type MaybeCardProps = {
    variant?: keyof typeof MaybeCardVariants
    details?: Omit<SharedType.UserMemberCardDetails, 'cardUrl' | 'imageUrl'>
    flipped: boolean
}

const now = new Date()

export function MaybeCard({ variant = 'default', details, flipped }: MaybeCardProps) {
    const container = useRef<HTMLDivElement>(null)
    const mouseX = useMotionValue(0.5)
    const mouseY = useMotionValue(0.5)
    const rotateX = useTransform(mouseY, [0, 1], ['-15deg', '15deg'])
    const rotateY = useTransform(mouseX, [0, 1], ['15deg', '-15deg'])
    const rotateYOffset = useMotionValue('0deg')

    const mouseMove = (e: MouseEvent<HTMLDivElement>) => {
        if (!container.current) return

        const rect = container.current.getBoundingClientRect()
        animate(mouseX, (e.clientX - rect.left) / rect.width)
        animate(mouseY, (e.clientY - rect.top) / rect.height)
    }

    const mouseLeave = () => {
        animate(mouseX, 0.5, { duration: 0.3 })
        animate(mouseY, 0.5, { duration: 0.3 })
    }

    useEffect(() => {
        animate(rotateYOffset, flipped ? '180deg' : '0deg', { duration: 0.5 })
    }, [rotateYOffset, flipped])

    return (
        <motion.div
            ref={container}
            className={classNames('overflow-hidden', MaybeCardVariants[variant])}
            onPointerMove={mouseMove}
            onPointerLeave={mouseLeave}
            style={
                {
                    ...(variant === 'settings'
                        ? {
                              backgroundImage: `
                                  radial-gradient(150% 150% at 50% 100%, #1C1C20, transparent 100%),
                                  repeating-linear-gradient(to right, transparent 0, #232428 1px, transparent 1px, transparent 20px),
                                  repeating-linear-gradient(to bottom, transparent 0, #232428 1px, transparent 1px, transparent 20px)
                              `,
                              backgroundSize: '100% 100%',
                              //backgroundPosition: '-10px -10px',
                          }
                        : undefined),

                    '--mx': mouseX,
                    '--my': mouseY,
                    '--rx': rotateX,
                    '--ry': rotateY,
                    '--ryo': rotateYOffset,
                    perspective: '1000px',
                } as CSSProperties
            }
        >
            <div className="relative w-[278px] h-[400px]" style={{ transformStyle: 'preserve-3d' }}>
                {['front', 'back'].map((face) => (
                    <div
                        key={face}
                        className="absolute inset-0 p-px rounded-2xl shadow-2xl bg-gray-800"
                        style={{
                            backgroundImage: `
                                radial-gradient(107% 89% at calc((var(--mx) - 0.5) * 50% - 5%) calc((var(--my) - 0.5) * 50% - 25%), #4CC9F0FF, transparent 100%),
                                radial-gradient(87% 71% at calc((var(--mx) - 0.5) * 50% + 90%) calc((var(--my) - 0.5) * 50% + 125%), #F72585FF, transparent 100%)
                            `,
                            transform: `rotateY(calc(var(--ry) + var(--ryo) + ${
                                face === 'front' ? '0deg' : '180deg'
                            })) rotateX(var(--rx))`,
                            backfaceVisibility: 'hidden',
                        }}
                    >
                        <div className="relative flex flex-col items-center justify-end p-6 w-full h-full rounded-2xl bg-black overflow-hidden">
                            {/* Logo */}
                            <div
                                className={classNames(
                                    "absolute bg-[url('/assets/maybe-black.svg')] bg-no-repeat bg-contain",
                                    details === undefined && 'hidden',
                                    face === 'front'
                                        ? 'w-[130%] h-full top-[10%] left-[22%] opacity-30 mix-blend-multiply'
                                        : 'w-[15%] h-full bottom-8 left-[50%] -translate-x-1/2 bg-bottom opacity-[7%] invert'
                                )}
                            ></div>

                            {/* Colored Lights */}
                            <div
                                className={classNames(
                                    'absolute inset-0 opacity-50',
                                    face === 'back' && 'scale-x-[-1]'
                                )}
                                style={{
                                    backgroundImage: `
                                        radial-gradient(150% 100% at calc((var(--mx) - 0.5) * 25% - 55%) calc((var(--my) - 0.5) * 25% - 55%), #4CC9F0ff, transparent 100%),
                                        radial-gradient(100% 66% at calc((var(--mx) - 0.5) * 25% + 70%) calc((var(--my) - 0.5) * 15% + 140%), #F72585ff, transparent 100%)
                                    `,
                                }}
                            ></div>

                            {/* Shine */}
                            <div
                                className={classNames(
                                    'absolute inset-0 mix-blend-hard-light',
                                    face === 'front' ? 'opacity-40' : 'opacity-30 scale-x-[-1]'
                                )}
                                style={{
                                    backgroundImage: `
                                        linear-gradient(20deg, #000a, transparent 50%),
                                        linear-gradient(135deg, #fff0 27%, #fff2 36%, #fff3 39%, #fff3 41%, #fff2 44%, #fff0 53%),
                                        linear-gradient(135deg, #fff0 47%, #fff2 56%, #fff3 59%, #fff3 61%, #fff2 64%, #fff0 73%)
                                    `,
                                    backgroundPosition:
                                        'calc((var(--mx) - 0.5) * 25% + 50%) calc((var(--my) - 0.5) * 25% + 50%)',
                                    backgroundSize: '200% 200%',
                                }}
                            ></div>

                            {details === undefined ? (
                                <div className="grow w-full flex justify-center items-center">
                                    <LoadingSpinner variant="secondary" />
                                </div>
                            ) : face === 'front' ? (
                                <>
                                    <span className="text-sm text-gray-100">
                                        #{(details?.memberNumber ?? 0).toString().padStart(3, '0')}
                                    </span>
                                    <span className="mt-1 text-lg text-white">
                                        {details?.name ?? 'Maybe User'}
                                    </span>
                                    <span className="text-lg text-gray-100">
                                        {details?.title ?? <>&nbsp;</>}
                                    </span>
                                    <span className="mt-1.5 text-sm text-gray-100">
                                        Joined{' '}
                                        {DateTime.fromJSDate(details?.joinDate ?? now).toFormat(
                                            'LL.dd.yy'
                                        )}
                                    </span>
                                </>
                            ) : (
                                <div className="grow w-full text-left">
                                    <div className="text-sm text-gray-100">Your Maybe</div>
                                    <div className="mt-3 text-lg text-white">{details?.maybe}</div>
                                </div>
                            )}
                        </div>
                    </div>
                ))}
            </div>
        </motion.div>
    )
}
