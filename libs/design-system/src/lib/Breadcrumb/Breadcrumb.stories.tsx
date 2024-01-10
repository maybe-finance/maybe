import type { Story, Meta } from '@storybook/react'
import type { BreadcrumbProps } from './Breadcrumb'

import Breadcrumb from './Breadcrumb'

export default {
    title: 'Components/Breadcrumbs',
    component: Breadcrumb,
    parameters: { controls: { exclude: ['as', 'className'] } },
    argTypes: {},
    args: {},
} as Meta

const Template: Story<BreadcrumbProps> = (args) => (
    <Breadcrumb.Group {...args}>
        <Breadcrumb href="/">asdf</Breadcrumb>
        <Breadcrumb>asdf</Breadcrumb>
    </Breadcrumb.Group>
)

export const Base = Template.bind({})
