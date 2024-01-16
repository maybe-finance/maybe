/// <reference types="vitest" />
import { defineConfig } from 'vite'

import viteTsConfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
    server: {
        port: 4200,
        host: 'localhost',
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
