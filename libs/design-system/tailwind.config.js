const { join } = require('path')
const defaultTheme = require('tailwindcss/defaultTheme')

/** @type {import('tailwindcss').Config} */
module.exports = {
    content: [join(__dirname, 'src/**/*.tsx'), join(__dirname, 'docs/**/*.{tsx,mdx}')],
    theme: {
        screens: {
            xs: '375px',
            sm: '640px',
            md: '744px',
            lg: '1024px',
            xl: '1440px',
        },
        colors: {
            transparent: 'transparent',
            current: 'currentColor',
            black: '#16161A',
            white: '#F8F9FA',
            gray: {
                DEFAULT: '#34363C',
                25: '#DEE2E6',
                50: '#ADB5BD',
                100: '#868E96',
                200: '#4B4F55',
                300: '#44474C',
                400: '#3D4045',
                500: '#34363C',
                600: '#2C2D32',
                700: '#232428',
                800: '#1C1C20',
            },
            cyan: {
                DEFAULT: '#3BC9DB',
                50: '#D7F6FA',
                300: '#99E9F2',
                400: '#66D9E8',
                500: '#3BC9DB',
            },
            red: {
                DEFAULT: '#FF8787',
                50: '#FFE8E8',
                300: '#FFC9C9',
                400: '#FFA8A8',
                500: '#FF8787',
            },
            teal: {
                DEFAULT: '#38D9A9',
                50: '#D6FAEE',
                300: '#96F2D7',
                400: '#63E6BE',
                500: '#38D9A9',
            },
            yellow: {
                DEFAULT: '#FFCA28',
                50: '#FFF2CB',
                300: '#FFE082',
                400: '#FFD54F',
                500: '#FFCA28',
            },
            blue: {
                DEFAULT: '#4DABF7',
                50: '#DBEEFF',
                300: '#A5D8FF',
                400: '#74C0FC',
                500: '#4DABF7',
            },
            orange: {
                DEFAULT: '#FFA94D',
                50: '#FFEEDA',
                300: '#FFD8A8',
                400: '#FFC078',
                500: '#FFA94D',
            },
            pink: {
                DEFAULT: '#F783AC',
                50: '#FFE5EE',
                300: '#FCC2D7',
                400: '#FAA2C1',
                500: '#F783AC',
            },
            grape: {
                DEFAULT: '#DA77F2',
                50: '#F9E4FD',
                300: '#EEBEFA',
                400: '#E599F7',
                500: '#DA77F2',
            },
            indigo: {
                DEFAULT: '#748FFC',
                50: '#E3E8FF',
                300: '#BAC8FF',
                400: '#91A7FF',
                500: '#748FFC',
            },
            green: {
                DEFAULT: '#66BB6A',
                50: '#E3F2E3',
                300: '#A5D6A7',
                400: '#81C784',
                500: '#66BB6A',
            },
        },
        fontFamily: {
            sans: ['Inter', ...defaultTheme.fontFamily.sans],
            display: ['Monument Extended', ...defaultTheme.fontFamily.sans],
            mono: defaultTheme.fontFamily.mono,
        },
        fontSize: {
            sm: ['0.75rem', '1rem'],
            base: ['0.875rem', '1.5rem'],
            lg: ['1rem', '1.5rem'],
            xl: ['1.125rem', '1.5rem'],
            '2xl': ['1.25rem', '2rem'],
            '3xl': ['1.5rem', '2rem'],
            '4xl': ['1.875rem', '2.5rem'],
            '5xl': ['2.5rem', '3.5rem'],
        },
        extend: {
            boxShadow: {
                DEFAULT: '0px 1px 2px 0px rgba(0, 0, 0, 0.1)',
                md: '0px 1px 4px 0px rgba(0, 0, 0, 0.25)',
                lg: '0px 2px 4px 1px rgba(0, 0, 0, 0.3)',
            },
            backgroundImage: {
                shine: 'linear-gradient(to right, transparent, transparent, #FFF1, transparent, transparent)',
            },
            keyframes: {
                shine: {
                    '0%': {
                        transform: 'translateX(-100%)',
                    },
                    '100%': {
                        transform: 'translateX(100%)',
                    },
                },
                appearUp: {
                    '0%': {
                        transformOrigin: 'center',
                        transform: 'translateY(50%) scale(0.8)',
                        opacity: 0,
                    },
                    '100%': {
                        transformOrigin: 'center',
                        transform: 'translateY(0) scale(1)',
                        opacity: 1,
                    },
                },
            },
            animation: {
                shine: 'shine 1.8s infinite',
                appearUp: 'appearUp 0.3s',
            },
        },
    },
}
