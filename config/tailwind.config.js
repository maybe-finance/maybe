const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  safelist: [
    'bg-morning',
    'bg-afternoon',
    'bg-evening',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
        display: ['GeneralSans, sans-serif'],
      },
      fontSize: {
        '2xs': '.625rem',
      },
      colors: {
        black: '#242629',
        offwhite: '#F9FAFB',
        white: '#fff',
      },
      backgroundImage: {
        'morning': "url('morning-gradient.svg')",
        'afternoon': "url('afternoon-gradient.svg')",
        'evening': "url('evening-gradient.svg')",
      },
      dropShadow: {
        'form': '0px 4px 10px rgba(52, 54, 60, 0.08)',
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}