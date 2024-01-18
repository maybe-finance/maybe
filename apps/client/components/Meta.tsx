import Head from 'next/head'
import React from 'react'
import env from '../env'

export default function Meta() {
    return (
        <Head>
            {/* <!-- Primary Meta Tags --> */}
            <title>Maybe</title>
            <meta name="title" content="Maybe" />
            <meta name="description" content="Maybe is modern financial & investment planning" />

            {/* <!-- Open Graph / Facebook --> */}
            <meta property="og:type" content="website" />
            <meta property="og:url" content="https://www.maybe.co" />
            <meta property="og:title" content="Maybe" />
            <meta
                property="og:description"
                content="Maybe is modern financial & investment planning"
            />

            {/* <!-- Twitter --> */}
            <meta property="twitter:card" content="summary_large_image" />
            <meta property="twitter:url" content="https://www.maybe.co" />
            <meta property="twitter:title" content="Maybe" />
            <meta
                property="twitter:description"
                content="Maybe is modern financial & investment planning"
            />

            {/* <!-- Favicons - https://realfavicongenerator.net/favicon_checker#.YUNEifxKhhE --> */}
            <link rel="manifest" href="/assets/site.webmanifest" />

            {/* <!-- Safari --> */}
            <link rel="apple-touch-icon" sizes="180x180" href="/assets/apple-touch-icon.png" />
            <link rel="mask-icon" href="/assets/safari-pinned-tab.svg" color="#4361ee" />

            {/* <!-- Chrome --> */}
            <link rel="icon" type="image/png" sizes="32x32" href="/assets/favicon-32x32.png" />
            <link rel="icon" type="image/png" sizes="16x16" href="/assets/favicon-16x16.png" />

            <link
                href="https://cdn.jsdelivr.net/npm/remixicon@2.5.0/fonts/remixicon.css"
                rel="stylesheet"
            />

            {/* <!-- NEXT_PUBLIC_ env variables --> */}
            <script src="/__appenv.js" />
        </Head>
    )
}
