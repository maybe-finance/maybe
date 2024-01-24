import { create } from '@storybook/theming'
import logo from '../assets/logo.svg'

export default create({
    base: 'dark',

    brandTitle: 'Maybe',
    brandUrl: 'https://maybe.co',
    brandImage: logo,

    fontBase: '"General Sans", sans-serif',

    colorPrimary: '#4361EE',
    colorSecondary: '#F12980',

    appBg: '#1C1C20',
    appContentBg: '#16161A',
})
