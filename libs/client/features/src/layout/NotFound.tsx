import { Button } from '@maybe-finance/design-system'
import Link from 'next/link'

function NotFoundSVG() {
    return (
        <svg
            className="max-w-xs px-8 mb-10 sm:p-0"
            viewBox="0 0 325 92"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
        >
            <rect
                x="67.4531"
                y="24.5283"
                width="30.6604"
                height="18.3962"
                rx="9.19811"
                fill="#4361EE"
            />
            <rect
                x="294.34"
                y="24.5283"
                width="30.6604"
                height="18.3962"
                rx="9.19811"
                fill="#4361EE"
            />
            <rect
                x="18.3965"
                y="24.5283"
                width="36.7925"
                height="18.3962"
                rx="9.19811"
                fill="#4361EE"
            />
            <rect
                x="245.283"
                y="24.5283"
                width="36.7925"
                height="18.3962"
                rx="9.19811"
                fill="#4361EE"
            />
            <rect
                x="67.4531"
                y="73.5848"
                width="30.6604"
                height="18.3962"
                rx="9.19811"
                fill="#F72585"
            />
            <rect
                x="294.34"
                y="73.5848"
                width="30.6604"
                height="18.3962"
                rx="9.19811"
                fill="#F72585"
            />
            <rect
                x="183.963"
                y="24.5283"
                width="30.6604"
                height="18.3962"
                rx="9.19811"
                fill="#4361EE"
            />
            <rect
                x="119.576"
                y="24.5283"
                width="30.6604"
                height="18.3962"
                rx="9.19811"
                fill="#4361EE"
            />
            <rect
                x="141.037"
                y="73.5848"
                width="49.0566"
                height="18.3962"
                rx="9.19811"
                fill="#F72585"
            />
            <g className="animate-flicker-fast">
                <rect x="52.123" width="45.9906" height="18.3962" rx="9.19811" fill="#4CC9F0" />
                <rect x="279.01" width="45.9906" height="18.3962" rx="9.19811" fill="#4CC9F0" />
                <rect x="141.037" width="49.0566" height="18.3962" rx="9.19811" fill="#4CC9F0" />
            </g>
            <g className="animate-flicker-slow">
                <rect
                    x="116.51"
                    y="49.0566"
                    width="33.7264"
                    height="18.3962"
                    rx="9.19811"
                    fill="#7209B7"
                />
                <rect
                    x="183.963"
                    y="49.0566"
                    width="30.6604"
                    height="18.3962"
                    rx="9.19811"
                    fill="#7209B7"
                />
                <rect y="49.0566" width="98.1132" height="18.3962" rx="9.19811" fill="#7209B7" />
                <rect
                    x="226.887"
                    y="49.0566"
                    width="98.1132"
                    height="18.3962"
                    rx="9.19811"
                    fill="#7209B7"
                />
            </g>
        </svg>
    )
}

export function NotFoundPage() {
    return (
        <div className="h-screen flex flex-col items-center justify-center p-4">
            <NotFoundSVG />

            <h1 className="mb-2 font-extrabold text-base md:text-2xl text-white">
                Welp, this is awkward.
            </h1>

            <p className="mb-10 text-base text-gray-50">
                Looks like this page didn’t survive the economic downturn.
            </p>

            {/* TODO: Add forwardRef functionality to Button so this doesn't throw a warning */}
            <Link href="/" passHref legacyBehavior>
                <Button>Back to dashboard</Button>
            </Link>
        </div>
    )
}

export default NotFoundPage
