import withNx from '@nrwl/next/plugins/with-nx'
import nextBundleAnalyzer from '@next/bundle-analyzer'

import { withSentryConfig } from '@sentry/nextjs'

const withBundleAnalyzer = nextBundleAnalyzer({
    enabled: process.env.ANALYZE === 'true',
})

const sentryConfig = {
    options: {
        automaticVercelMonitors: true,
        disableLogger: true,
        hideSourceMaps: true,
        transpileClientSDK: false,
        tunnelRoute: '/monitoring',
        widenClientFileUpload: true,
    },
    webpack: {
        // TODO: Add actual org and project
        org: 'maybe-finance',
        project: 'maybe',
        silent: true,
    },
}

/**
 * @type {import('@nrwl/next/plugins/with-nx').WithNxOptions}
 **/
const nextConfig = {
    nx: {
        // Set this to true if you would like to to use SVGR
        // See: https://github.com/gregberge/svgr
        svgr: false,
    },
    images: {
        loader: 'custom',
    },
}

module.exports = withBundleAnalyzer(
    withNx(withSentryConfig(nextConfig, sentryConfig, sentryConfig.webpack, sentryConfig.options))
)
