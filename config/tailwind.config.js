const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  safelist: [
    {
      pattern: /^bg-account-/,
    }
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      fontSize: {
        '2xs': '.625rem',
      },
      colors: {
        black: '#242629',
        offwhite: '#F9FAFB',
        'account-depository': '#2E90FA',
        'account-investment': '#32D583',
        'account-property': '#F23E94',
        'account-vehicle': '#6172F3',
        'account-credit': '#36BFFA',
        'account-loan': '#F38744',
        'account-other-asset': '#12B76A',
        'account-other-liability': '#F04438',
      },
      dropShadow: {
        'form': '0px 4px 10px rgba(52, 54, 60, 0.08)',
      },
      boxShadow: {
        'xs': '0px 1px 2px 0px #1018280D'
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
