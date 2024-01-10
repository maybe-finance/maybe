import { Button } from '@maybe-finance/design-system'
import classNames from 'classnames'
import { Duration } from 'luxon'
import { useMemo, useState } from 'react'
import { RiCloseFill, RiPauseFill, RiPlayFill } from 'react-icons/ri'

const AudioPlayerVariants = Object.freeze({
    normal: 'bg-gray-800 px-5 py-4 gap-4',
    upload: 'bg-gray-700 px-3 py-2 gap-3',
})

export type AudioPlayerVariant = keyof typeof AudioPlayerVariants

export type AudioPlayerProps = {
    src: string
    variant?: AudioPlayerVariant
    onClose?: () => void
    duration?: number
}

// TODO - enhance user controls for this basic player
export function AudioPlayer({
    src,
    variant = 'normal',
    onClose,
    duration: durationProp,
}: AudioPlayerProps) {
    const [duration, setDuration] = useState<number | undefined>(durationProp)
    const [currentTime, setCurrentTime] = useState(0)
    const [isPlaying, setIsPlaying] = useState(false)
    const [isLoaded, setIsLoaded] = useState(false)

    const player = useMemo(() => {
        return new Audio(src)
    }, [src])

    player.addEventListener('timeupdate', function () {
        const time = this.currentTime
        setCurrentTime(time)
    })

    player.addEventListener('play', function () {
        setIsPlaying(true)
    })

    player.addEventListener('pause', function () {
        setIsPlaying(false)
    })

    player.addEventListener('canplaythrough', function () {
        if (isFinite(player.duration)) setDuration(player.duration)

        setIsLoaded(true)
    })

    return (
        <div className={classNames(AudioPlayerVariants[variant], 'flex items-center rounded-xl')}>
            <Button variant="icon" disabled={!isLoaded}>
                {isPlaying ? (
                    <RiPauseFill size={24} onClick={() => player.pause()} />
                ) : (
                    <RiPlayFill size={24} onClick={() => player.play()} />
                )}
            </Button>
            <div className="relative grow h-[5px] bg-gray-25 bg-opacity-10 rounded-full">
                <div className="absolute inset-0"></div>

                {/* Progress line */}
                <div
                    className="h-[5px] bg-gray-25 rounded-full"
                    style={{ width: duration ? `${(currentTime / duration) * 100}%` : 0 }}
                ></div>

                {/* TODO - add back this progress circle for additional controls */}
                {/* <div
                    className="absolute rounded-full -top-1 -left-1 bg-gray-200 w-3 h-3"
                    style={{
                        left: !duration ? 0 : `${(currentTime / duration) * 100}%`,
                    }}
                ></div> */}
            </div>
            <span className="text-base">
                {Duration.fromObject({ seconds: duration }).toFormat(
                    duration && isFinite(duration) && duration >= 3600 ? 'hh:mm:ss' : 'mm:ss'
                )}
            </span>
            {variant === 'upload' && onClose && (
                <Button variant="icon" disabled={!isLoaded}>
                    <RiCloseFill
                        size={24}
                        onClick={() => {
                            player.pause()
                            onClose()
                        }}
                    />
                </Button>
            )}

            {/* For files recorded with MediaRecorder, duration does not seem to load (until played through once) due to the file being streamed - https://stackoverflow.com/q/31818821/7437737 */}
            <audio src={src} />
        </div>
    )
}
