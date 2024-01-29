import localFont from 'next/font/local'
import type { Metadata } from 'next/types'
import 'remixicon/fonts/remixicon.css'

const inter = localFont({
    src: [
        { path: '/assets/fonts/inter/Inter-Variable.woff2', weight: '100' },
        { path: '/assets/fonts/inter/Inter-Variable.woff2', weight: '900' },
    ],
    display: 'swap',
})

const monument_extended = localFont({
    src: [
        { path: '/assets/fonts/monument/MonumentExtended-Heavy.woff2', weight: '100' },
        { path: '/assets/fonts/monument/MonumentExtended-Heavy.woff2', weight: '200' },
        { path: '/assets/fonts/monument/MonumentExtended-Heavy.woff2', weight: '300' },
        { path: '/assets/fonts/monument/MonumentExtended-Heavy.woff2', weight: '400' },
        { path: '/assets/fonts/monument/MonumentExtended-Heavy.woff2', weight: '500' },
        { path: '/assets/fonts/monument/MonumentExtended-Heavy.woff2', weight: '700' },
        { path: '/assets/fonts/monument/MonumentExtended-Heavy.woff2', weight: '800' },
        { path: '/assets/fonts/monument/MonumentExtended-Heavy.woff2', weight: '900' },
    ],
    display: 'swap',
})

export const metadata: Metadata = {
    title: 'Maybe',
    description: 'Maybe is modern financial & investment planning',
    openGraph: {
        type: 'website',
        title: 'Maybe',
        description: 'Maybe is modern financial & investment planning',
        url: 'https://www.maybe.co',
    },
    twitter: {
        card: 'summary_large_image',
        title: 'Maybe',
        description: 'Maybe is modern financial & investment planning',
    },
    manifest: '/assets/site.webmanifest',
    icons: [
        { url: '/assets/favicon-32x32.png', sizes: '32x32' },
        { url: '/assets/favicon-16x16.png', sizes: '16x16' },
        { rel: 'apple-touch-icon', url: '', sizes: '180x180' },
        { rel: 'mask-icon', url: '/assets/safari-pinned-tab.svg', color: '#4361ee' },
    ],
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
    return (
        <html lang="en" className={`${inter.className} ${monument_extended.className}`}>
            <body>{children}</body>
        </html>
    )
}
