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
        25: '#DFE2E6',
        50: '#ADB5BC',
        100: '#878E95',
        200: '#4C4F54',
        300: '#44474C',
        400: '#3D4045',
        500: '#34363C',
        600: '#2C2D32',
        700: '#232428',
        800: '#1C1C20',
      },
      cyan: {
        50: '#DDF5F9',
        300: '#ABE7F1',
        400: '#85D6E6',
        500: '#69C6D9',
      },
      red: {
        50: '#ffe8e8',
        300: '#ffc9c9',
        400: '#ffa8a8',
        500: '#ff8787',
      },
      teal: {
        50: '#d6faee',
        300: '#96f2d7',
        400: '#63e6be',
        500: '#38d9a9',
      },
      yellow: {
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
