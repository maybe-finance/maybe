import { Button } from '@maybe-finance/design-system'
import Link from 'next/link'
import Image from 'next/image'

export default function Unauthorized() {
    return (
        <div className="h-screen flex flex-col items-center justify-center p-4">
            <Image src="/assets/maybe.svg" alt="maybe logo" width={150} height={150} />

            <h1 className="mb-2 mt-10 font-extrabold text-base md:text-2xl display text-white">
                Oops!
            </h1>

            <p className="mb-10 text-base text-center text-gray-50 max-w-md">
                You are not authorized to view this page. This app is for our registered advisors
                only.
            </p>

            <div className="flex items-center gap-2">
                <Link href="/api/auth/logout">
                    <Button variant="secondary">Logout</Button>
                </Link>
                <Link href="https://app.maybe.co">
                    <Button>Main App</Button>
                </Link>
            </div>
        </div>
    )
}
