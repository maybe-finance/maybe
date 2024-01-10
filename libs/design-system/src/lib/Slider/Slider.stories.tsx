import type { Story, Meta } from '@storybook/react'

import Slider from './Slider'

export default {
    title: 'Components/Slider',
    argTypes: {},
    args: {},
} as Meta

export const Base: Story = (_args) => (
    <div className="flex items-center justify-center">
        <div className="w-48 mx-auto w-full">
            <Slider initialValue={[]} onChange={(values: number[]) => console.log(values)} />
        </div>
    </div>
)
