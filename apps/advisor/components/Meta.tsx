import Head from 'next/head'
import React from 'react'

export default function Meta() {
    return (
        <Head>
            {/* <!-- Primary Meta Tags --> */}
            <title>Maybe Advisor</title>
            <meta name="title" content="Maybe Advisor" />
            <meta name="description" content="Maybe is modern financial & investment planning" />

            {/* <!-- Open Graph / Facebook --> */}
            <meta property="og:type" content="website" />
            <meta property="og:url" content="https://www.maybe.co" />
            <meta property="og:title" content="Maybe Advisor" />
            <meta
                property="og:description"
                content="Maybe is modern financial & investment planning"
            />
            <meta property="og:image" content="https://assets.maybe.co/images/maybe-meta.png" />

            {/* <!-- Favicons - https://realfavicongenerator.net/favicon_checker#.YUNEifxKhhE --> */}
            <link rel="manifest" href="/assets/site.webmanifest" />

            {/* <!-- Safari --> */}
            <link rel="apple-touch-icon" sizes="180x180" href="/assets/apple-touch-icon.png" />
            <link rel="mask-icon" href="/assets/safari-pinned-tab.svg" color="#4361ee" />

            {/* <!-- Chrome --> */}
            <link rel="icon" type="image/png" sizes="32x32" href="/assets/favicon-32x32.png" />
            <link rel="icon" type="image/png" sizes="16x16" href="/assets/favicon-16x16.png" />
        </Head>
    )
}
