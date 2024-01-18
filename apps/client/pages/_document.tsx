import { Html, Head, Main, NextScript } from 'next/document'

export default function Document() {
    return (
        <Html lang="en">
            <Head>
                {/* <!-- NEXT_PUBLIC_ env variables --> */}
                {/* eslint-disable-next-line @next/next/no-sync-scripts */}
                <script src="/__appenv.js" />
            </Head>
            <body>
                <Main />
                <NextScript />
            </body>
        </Html>
    )
}
