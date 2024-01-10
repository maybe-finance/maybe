import type { Story, Meta } from '@storybook/react'
import type { TrendLineProps } from '.'

import TrendLine from './TrendLine'

const data = Array.from({ length: 30 }, () => Math.random() * 10000).map((value, index) => ({
    key: index,
    value,
}))

export default {
    title: 'Components/TrendLine',
    component: TrendLine,
    parameters: { controls: { exclude: ['className'] } },
    args: {
        inverted: false,
        data,
    },
} as Meta

export const Base: Story<TrendLineProps> = (props) => (
    <div className="w-16 h-4">
        <TrendLine {...props} />
    </div>
)
