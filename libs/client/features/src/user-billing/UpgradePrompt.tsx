import { useRef, useState } from 'react'
import type { MouseEvent, CSSProperties } from 'react'
import { useUserApi } from '@maybe-finance/client/shared'
import { Button } from '@maybe-finance/design-system'
import { PremiumIcon } from './PremiumIcon'
import { animate, motion, useMotionValue } from 'framer-motion'
import { UpgradeTakeover } from './UpgradeTakeover'

export function UpgradePrompt() {
    const { useSubscription } = useUserApi()

    const { data, isSuccess } = useSubscription()

    const container = useRef<HTMLDivElement>(null)
    const mouseX = useMotionValue(0.5)
    const mouseY = useMotionValue(0.5)

    const mouseMove = (e: MouseEvent<HTMLDivElement>) => {
        if (!container.current) return

        const rect = container.current.getBoundingClientRect()
        animate(mouseX, (e.clientX - rect.left) / rect.width)
        animate(mouseY, (e.clientY - rect.top) / rect.height)
    }

    const [takeoverOpen, setTakeoverOpen] = useState(false)

    const trialDaysLeft = Math.ceil(data?.trialEnd?.diffNow('days').days ?? 0)

    return isSuccess && (!data?.subscribed || data.trialing) ? (
        <>
            <motion.div
                ref={container}
                className="p-[1px] rounded-lg"
                style={
                    {
                        '--mx': mouseX,
                        '--my': mouseY,
                        backgroundImage: `
                        linear-gradient(calc((var(--mx) + 0.5) * 45deg), #2C2D32EE 30%, transparent, #2C2D32EE 70%),
                        linear-gradient(148.38deg, #4CC9F0 28.24%, #4361EE 46.15%, #7209B7 61.01%, #F72585 80.62%)
                    `,
                    } as CSSProperties
                }
                onPointerMove={mouseMove}
            >
                <div
                    className="p-3 rounded-lg bg-gray-700"
                    style={{
                        backgroundImage: `
                        radial-gradient(farthest-corner circle at 30% calc((var(--my) - 0.5) * 100%), #4CC9F00F, transparent 50%),
                        radial-gradient(farthest-corner circle at 70% calc((var(--my) + 0.5) * 100%), #F725850F, transparent 50%)
                    `,
                    }}
                >
                    <div className="flex space-x-3">
                        <PremiumIcon size="md" className="shrink-0" />
                        <div className="grow text-base text-white cursor-default">
                            {data.trialing ? (
                                <>
                                    {trialDaysLeft} day{trialDaysLeft !== 1 ? 's' : ''} left in your
                                    free trial
                                </>
                            ) : (
                                <>Subscribe to continue using Maybe</>
                            )}
                        </div>
                    </div>
                    <div className="flex justify-end mt-2">
                        <Button
                            onClick={() => setTakeoverOpen(true)}
                            variant="secondary"
                            className="!py-1 !px-3"
                            data-testid="upgrade-prompt-upgrade-button"
                        >
                            Subscribe
                        </Button>
                    </div>
                </div>
            </motion.div>
            <UpgradeTakeover open={takeoverOpen} onClose={() => setTakeoverOpen(false)} />
        </>
    ) : null
}
