import type { Story, Meta } from '@storybook/react'
import { useState } from 'react'

import RadioGroup from './RadioGroup'

export default {
    title: 'Components/RadioGroup',
    component: RadioGroup,
    argTypes: {},
    args: {},
} as Meta

export const Base: Story = (args) => {
    const [value, setValue] = useState('option-1')

    return (
        <div className="flex items-center justify-center text-gray-100">
            <RadioGroup {...(args as any)} value={value} onChange={setValue}>
                <RadioGroup.Label className="sr-only">Selections</RadioGroup.Label>

                <RadioGroup.Option value="option-1">
                    <RadioGroup.Label>Option 1</RadioGroup.Label>
                </RadioGroup.Option>

                <RadioGroup.Option value="option-2">
                    <RadioGroup.Label>Option 2</RadioGroup.Label>
                </RadioGroup.Option>

                <RadioGroup.Option value="option-3">
                    <RadioGroup.Label>Option 3</RadioGroup.Label>
                </RadioGroup.Option>
            </RadioGroup>
        </div>
    )
}
