const { join } = require('path')
const merge = require('lodash/fp/merge')

// https://blog.nrwl.io/setup-next-js-to-use-tailwind-with-nx-849b7e21d8d0
const { createGlobPatternsForDependencies } = require('@nrwl/next/tailwind')

// TODO: Figure out how to simplify this import with scope
const designSystemConfig = require(__dirname + '/../../libs/design-system/tailwind.config.js')

module.exports = merge(designSystemConfig, {
    content: [
        join(__dirname, 'pages/**/*.{js,ts,jsx,tsx}'),
        join(__dirname, 'components/**/*.{js,ts,jsx,tsx}'),
        ...createGlobPatternsForDependencies(__dirname, '/**/!(*.stories|*.spec).{tsx,ts,jsx,js}'),
    ],
    theme: {
        extend: {
            transitionProperty: {
                width: 'width',
            },
            keyframes: {
                wave: {
                    '0%, 100%': { transform: 'rotate(0deg)' },
                    '50%': { transform: 'rotate(20deg)' },
                },
                float: {
                    from: { transform: 'rotate(0deg) translateX(2px) rotate(0deg)' },
                    to: { transform: 'rotate(360deg) translateX(2px) rotate(-360deg)' },
                },
            },
            animation: {
                wave: '3 wave 0.6s ease-in-out',
                float: 'float 4s infinite linear',
            },
            backgroundImage: {
                'login-background':
                    'radial-gradient(100% 100% at clamp(20%, calc(30% + var(--mx) * 0.05), 40%) clamp(50%, calc(50% + var(--my) * 0.05), 60%), #4361EE33 0%, #16161Af4 120%)',
            },
            typography: () => {
                const { white, gray, cyan } = designSystemConfig.theme.colors
                return {
                    light: {
                        css: {
                            '--tw-prose-body': white,
                            '--tw-prose-headings': white,
                            '--tw-prose-lead': white,
                            '--tw-prose-links': cyan['600'],
                            '--tw-prose-bold': white,
                            '--tw-prose-counters': white,
                            '--tw-prose-bullets': gray['50'],
                            '--tw-prose-hr': gray['500'],
                            '--tw-prose-quotes': gray['50'],
                            '--tw-prose-quote-borders': gray['50'],
                            '--tw-prose-captions': white,
                            '--tw-prose-code': gray['200'],
                            '--tw-prose-pre-code': gray['100'],
                            '--tw-prose-pre-bg': gray['600'],
                            '--tw-prose-th-borders': gray['50'],
                            '--tw-prose-td-borders': gray['50'],
                            '--tw-prose-invert-body': white,
                            '--tw-prose-invert-headings': white,
                            '--tw-prose-invert-lead': white,
                            '--tw-prose-invert-links': cyan['600'],
                            '--tw-prose-invert-bold': white,
                            '--tw-prose-invert-counters': white,
                            '--tw-prose-invert-bullets': gray['50'],
                            '--tw-prose-invert-hr': gray['500'],
                            '--tw-prose-invert-quotes': gray['50'],
                            '--tw-prose-invert-quote-borders': gray['50'],
                            '--tw-prose-invert-captions': white,
                            '--tw-prose-invert-code': gray['200'],
                            '--tw-prose-invert-pre-code': gray['100'],
                            '--tw-prose-invert-pre-bg': gray['600'],
                            '--tw-prose-invert-th-borders': gray['50'],
                            '--tw-prose-invert-td-borders': gray['50'],
                        },
                    },
                }
            },
        },
    },
    plugins: [
        require('@tailwindcss/line-clamp'),
        require('@tailwindcss/forms'),
        require('@tailwindcss/typography'),
    ],
})
