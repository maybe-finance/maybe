const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
  ],
  theme: {
    colors: {
      white: '#f8f9fa',
      black: '#16161a',
      gray: {
        25: '#dee2e6',
        50: '#adb5bd',
        100: '#868e96',
        200: '#4b4f55',
        300: '#44474c',
        400: '#3d4045',
        500: '#34363c',
        600: '#2c2d32',
        700: '#232428',
        800: '#1c1c20',
      },
      primary: {
        50: '#d7f6fa',
        300: '#d7f6fa',
        400: '#66d9e8',
        500: '#69c6d9',
      },
      error: {
        50: '#ffe8e8',
        300: '#ffc9c9',
        400: '#ffa8a8',
        500: '#ff8787',
      },
      success: {
        50: '#d6faee',
        300: '#96f2d7',
        400: '#63e6be',
        500: '#38d9a9',
      },
      warning: {
        50: '#fff2cb',
        300: '#ffe082',
        400: '#ffd54f',
        500: '#ffca28',
      },
      blue: {
        50: '#dbeeff',
        300: '#a5d8ff',
        400: '#74c0fc',
        500: '#4dabf7',
      },
      orange: {
        50: '#ffeeda',
        300: '#ffd8a8',
        400: '#ffc078',
        500: '#ffa94d',
      },
      pink: {
        50: '#ffe5ee',
        300: '#fcc2d7',
        400: '#faa2c1',
        500: '#f783ac',
      },
      grape: {
        50: '#f9e4fd',
        300: '#eebefa',
        400: '#e599f7',
        500: '#da77f2',
      },
      indigo: {
        50: '#e3e8ff',
        300: '#bac8ff',
        400: '#91a7ff',
        500: '#748ffc',
      },
      green: {
        50: '#e3f2e3',
        300: '#a5d6a7',
        400: '#81c784',
        500: '#66bb6a',
      },
    },
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      colors: {},
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
