import '../assets/styles.css'

import theme from './theme'

export const parameters = {
    actions: { argTypesRegex: '^on[A-Z].*' },
    viewMode: 'docs', // Show Docs tab by default
    controls: {
        matchers: {
            color: /(background|color)$/i,
            date: /Date$/,
        },
    },
    backgrounds: {
        default: 'dark',
        values: [
            {
                name: 'dark',
                value: '#16161A',
            },
        ],
    },
    docs: {
        theme,
    },
    options: {
        storySort: {
            order: ['Getting Started', ['About', 'Colors', 'Typography'], 'Components'],
        },
    },
}
