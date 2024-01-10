import { scaleOrdinal } from '@visx/scale'

export const tailwindScale = scaleOrdinal({
    domain: [
        'white',
        'gray',
        'gray-100',
        'cyan',
        'red',
        'teal',
        'yellow',
        'blue',
        'orange',
        'pink',
        'grape',
        'indigo',
        'green',
    ],
    range: [
        '#F8F9FA',
        '#34363C',
        '#868E96',
        '#3BC9DB',
        '#FF8787',
        '#38D9A9',
        '#FFCA28',
        '#4DABF7',
        '#FFA94D',
        '#F783AC',
        '#DA77F2',
        '#748FFC',
        '#66BB6A',
    ],
}).unknown('#3BC9DB') // default to cyan

export const tailwindBgScale = scaleOrdinal({
    domain: ['cyan', 'grape', 'red', 'gray'],
    range: ['#1A282D', '#2A2030', '#2D2125', '#232428'],
}).unknown('#1A282D') // default to cyan
