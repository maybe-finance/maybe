import { Button } from '@maybe-finance/design-system'
import Link from 'next/link'

export default function UpgradePage() {
    return (
        <div className="h-screen flex flex-col justify-center items-center space-y-4">
            <h3>Signups have been disabled.</h3>
            <p>
                Maybe will be shutting down on July 31.{' '}
                <Link
                    className="text-cyan-500 underline hover:text-cyan-400"
                    href="https://maybefinance.notion.site/To-Investors-Customers-The-Future-of-Maybe-6758bfc0e46f4ec68bf4a7a8f619199f"
                >
                    Details and FAQ
                </Link>
            </p>
            <Button href="/">Back home</Button>
        </div>
    )
}
