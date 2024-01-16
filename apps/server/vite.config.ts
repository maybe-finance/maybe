/// <reference types="vitest" />
import { defineConfig } from 'vite'

import viteTsConfigPaths from 'vite-tsconfig-paths'
import env from './src/env'

export default defineConfig({
    server: {
        port: Number(env.NX_PORT),
        host: 'localhost',
        proxy: {
            '/v1': {
                target: `http://localhost:${env.NX_PORT}`,
                changeOrigin: true,
                rewrite: (path) => path.replace(/^\/v1/, ''),
            },
        },
    },
    optimizeDeps: {
        exclude: ['mock-aws-s3', 'aws-sdk'],
    },

    plugins: [
        viteTsConfigPaths({
            root: '../../',
        }),
    ],

    // Uncomment this if you are using workers.
    // worker: {
    //  plugins: [
    //    viteTsConfigPaths({
    //      root: '../../',
    //    }),
    //  ],
    // },
})
