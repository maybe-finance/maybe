import { useEffect, useRef } from 'react'

export type AudioVisualizerProps = {
    stream: MediaStream
}

const BAR_WIDTH = 6

export function AudioVisualizer({ stream }: AudioVisualizerProps) {
    const wrapper = useRef<HTMLDivElement>(null)
    const canvas = useRef<HTMLCanvasElement>(null)

    const frameRequest = useRef<number>()
    const analyser = useRef<AnalyserNode>()
    const data = useRef<Uint8Array>()

    useEffect(() => {
        if (wrapper.current && canvas.current) {
            canvas.current.width = wrapper.current.offsetWidth
            canvas.current.height = wrapper.current.offsetHeight
        }
    })

    useEffect(() => {
        const audioContext = new AudioContext()
        const source = audioContext.createMediaStreamSource(stream)

        analyser.current = audioContext.createAnalyser()
        source.connect(analyser.current)

        analyser.current.fftSize = 32
        const bufferLength = analyser.current.frequencyBinCount
        data.current = new Uint8Array(bufferLength)
    }, [stream])

    const render = () => {
        const ctx = canvas.current?.getContext('2d')
        if (canvas.current == null || !ctx || !analyser.current || !data.current) return

        analyser.current.getByteFrequencyData(data.current)

        const canvasWidth = canvas.current.width
        const canvasHeight = canvas.current.height

        ctx.clearRect(0, 0, canvasWidth, canvasHeight)

        const space = canvas.current.width / data.current.length

        data.current.forEach((value, index) => {
            const barHeight = Math.max(value > 0 ? (value * canvasHeight) / 255 : 0, BAR_WIDTH)

            ctx.fillStyle = barHeight > BAR_WIDTH ? '#3BC9DB' : '#4B4F55'
            roundRect(
                ctx,
                canvasWidth / 2 + (index * space) / 2,
                canvasHeight / 2 - barHeight / 2,
                BAR_WIDTH,
                barHeight,
                1000
            )
            ctx.fill()
            roundRect(
                ctx,
                canvasWidth / 2 - (index * space) / 2,
                canvasHeight / 2 - barHeight / 2,
                BAR_WIDTH,
                barHeight,
                1000
            )
            ctx.fill()
        })

        frameRequest.current = requestAnimationFrame(render)
    }

    useEffect(() => {
        frameRequest.current = requestAnimationFrame(render)

        return () => {
            if (frameRequest.current != null) cancelAnimationFrame(frameRequest.current)
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [])

    return (
        <div ref={wrapper} className="w-full h-full">
            <canvas ref={canvas} width="100%" height="100%"></canvas>
        </div>
    )
}

function roundRect(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    width: number,
    height: number,
    radius: number
) {
    if (width < 2 * radius) radius = width / 2
    if (height < 2 * radius) radius = height / 2
    ctx.beginPath()
    ctx.moveTo(x + radius, y)
    ctx.arcTo(x + width, y, x + width, y + height, radius)
    ctx.arcTo(x + width, y + height, x, y + height, radius)
    ctx.arcTo(x, y + height, x, y, radius)
    ctx.arcTo(x, y, x + width, y, radius)
    ctx.closePath()
}
