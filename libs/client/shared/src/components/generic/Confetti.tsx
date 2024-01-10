import React, { useRef, useEffect, useCallback, memo } from 'react'
import ReactDOM from 'react-dom'
import classNames from 'classnames'
import { useFrame } from '../../hooks/useFrame'

export type Particle = {
    color: string
    x: number
    y: number
    width: number
    height: number
    scaleY: number
    rotation: number
    velocityX: number
    velocityY: number
}

export type ConfettiProps = {
    /** Number of confetti particles */
    amount?: number

    /** Whether to continue respawning particles at the top of the screen */
    respawn?: boolean

    /** Array of particle colors */
    colors?: string[]

    /** Amount of resistance slowing down horizontal velocity */
    drag?: number

    /** Rate at which vertical velocity increases */
    gravity?: number

    /** Amount of back-and-forth horizontal motion */
    sway?: number

    /** Rate at which particles rotate along their x-axes */
    flutter?: number

    /** Whether to randomly rotate particles along their z-axes */
    rotate?: boolean

    extendGenerateParticle?: (particle: Particle, context: CanvasRenderingContext2D) => Particle
    renderParticle?: (particle: Particle, context: CanvasRenderingContext2D) => void
    resizeDebounceTimeout?: number
    className?: string
}

function ConfettiBase({
    amount = 100,
    respawn = true,
    colors = ['#4cc9f0', '#4361ee', '#7209b7', '#f12980'],
    drag = 0.05,
    gravity = 0.015,
    sway = 1,
    flutter = 0.05,
    rotate = true,
    extendGenerateParticle,
    renderParticle,
    resizeDebounceTimeout = 250,
    className,
    ...rest
}: ConfettiProps): JSX.Element {
    const canvasRef = useRef<HTMLCanvasElement>(null)

    const particles = useRef<Particle[]>([])

    const generateParticle = useCallback(
        (context: CanvasRenderingContext2D): Particle => {
            const particle = {
                color: colors[Math.floor(Math.random() * colors.length)],
                x: Math.random() * context.canvas.width,
                y:
                    gravity > 0
                        ? -Math.random() * context.canvas.height
                        : Math.random() * context.canvas.height + context.canvas.height,
                width: Math.random() * 10 + 5,
                height: Math.random() * 10 + 5,
                scaleY: 1,
                rotation: rotate ? Math.random() * 2 * Math.PI : 0,
                velocityX: Math.random() * sway * 50 - sway * 25,
                velocityY: Math.random() * gravity * 500,
            }

            return extendGenerateParticle ? extendGenerateParticle(particle, context) : particle
        },
        [colors, gravity, rotate, sway, extendGenerateParticle]
    )

    const generateParticles = useCallback(
        (context: CanvasRenderingContext2D, amount: number): Particle[] => {
            const particles: Particle[] = []

            for (let i = 0; i < amount; ++i) {
                particles.push(generateParticle(context))
            }

            return particles
        },
        [generateParticle]
    )

    useFrame((_, rawDeltaTime) => {
        const context = canvasRef.current?.getContext('2d')
        if (!context) return

        const deltaTime = rawDeltaTime / 16.7 // Normalize to 60 FPS

        context.clearRect(0, 0, context.canvas.width, context.canvas.height)
        particles.current = particles.current.map((particle) => {
            // Slow down x-velocity over time
            particle.velocityX -= particle.velocityX * drag * deltaTime

            // Add randomly positive/negative value to make the particle sway
            particle.velocityX += (Math.random() > 0.5 ? 1 : -1) * Math.random() * sway * deltaTime

            // Increase y-velocity with gravity
            particle.velocityY += gravity * deltaTime

            // Spin/flutter particle as it falls
            particle.scaleY = Math.cos(particle.y * flutter * deltaTime)

            particle.x += particle.velocityX * deltaTime
            particle.y += particle.velocityY * deltaTime

            const width = particle.width,
                height = particle.height * particle.scaleY

            context.save()
            context.translate(particle.x, particle.y)
            context.rotate(particle.rotation)
            context.fillStyle = particle.color
            renderParticle
                ? renderParticle(particle, context)
                : context.fillRect(-width / 2, -height / 2, width, height)
            context.restore()

            const buffer = Math.sqrt(Math.pow(width, 2) + Math.pow(height, 2)) / 2
            const outOfBounds =
                gravity > 0 ? particle.y - buffer > context.canvas.height : particle.y + buffer < 0

            return respawn && outOfBounds ? generateParticle(context) : particle
        })
    })

    const updateCanvasSize = React.useCallback(() => {
        if (canvasRef.current) {
            canvasRef.current.width = window.innerWidth
            canvasRef.current.height = window.innerHeight
        }
    }, [])

    // Keep canvas size updated with window
    useEffect(() => {
        updateCanvasSize()

        let timeout: number | null = null
        const handleResize = () => {
            timeout !== null && window.clearTimeout(timeout)
            timeout = window.setTimeout(updateCanvasSize, resizeDebounceTimeout)
        }

        window.addEventListener('resize', handleResize)
        return () => window.removeEventListener('resize', handleResize)
    }, [resizeDebounceTimeout, updateCanvasSize])

    // Generate particles
    useEffect(() => {
        if (canvasRef.current) {
            const context = canvasRef.current?.getContext('2d')
            if (context) particles.current = generateParticles(context, amount)
        }
    }, [amount, generateParticles])

    return ReactDOM.createPortal(
        <canvas
            ref={canvasRef}
            className={classNames(
                'z-50 fixed inset-0 w-screen h-screen pointer-events-none',
                className
            )}
            {...rest}
        ></canvas>,
        document.body
    )
}

export const Confetti = memo(ConfettiBase)
