import type { Story, Meta } from '@storybook/react'
import type { CheckboxProps } from './Checkbox'
import { useState } from 'react'

import Checkbox from './Checkbox'

export default {
    title: 'Components/Checkbox',
    component: Checkbox,
    parameters: { controls: { exclude: ['className', 'onClick'] } },
    args: {
        label: 'Check something',
    },
} as Meta

const Template: Story<CheckboxProps> = (args) => {
    const [enabled, setEnabled] = useState(args.checked)

    return <Checkbox {...args} checked={enabled} onChange={(checked) => setEnabled(checked)} />
}

export const Base = Template.bind({})
