import type { Story, Meta } from '@storybook/react'
import type { ToggleProps } from './Toggle'
import { useState } from 'react'

import Toggle from './Toggle'

export default {
    title: 'Components/Toggle',
    component: Toggle,
    parameters: { controls: { exclude: ['className', 'onClick'] } },
    args: {
        screenReaderLabel: 'Toggle something',
    },
} as Meta

const Template: Story<ToggleProps> = (args) => {
    const [enabled, setEnabled] = useState(args.checked)

    return <Toggle {...args} checked={enabled} onChange={(checked) => setEnabled(checked)} />
}

export const Base = Template.bind({})
