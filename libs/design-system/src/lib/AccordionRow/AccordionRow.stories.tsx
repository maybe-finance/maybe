import type { AccordionRowProps } from './AccordionRow'
import type { Story, Meta } from '@storybook/react'

import AccordionRow from './AccordionRow'

export default {
    title: 'Components/AccordionRow',
    component: AccordionRow,
    parameters: { controls: { exclude: ['className', 'children'] } },
    argTypes: {
        label: {
            control: 'text',
            description: 'List label/title',
        },
    },
    args: {
        label: 'Level 0',
        collapsible: true,
    },
} as Meta

const Template: Story<AccordionRowProps> = (args) => (
    <AccordionRow {...args}>
        <AccordionRow label="Level 1" collapsible={true} level={1}>
            <AccordionRow label="Level 2" level={2} />
        </AccordionRow>
    </AccordionRow>
)

export const Base = Template.bind({})
