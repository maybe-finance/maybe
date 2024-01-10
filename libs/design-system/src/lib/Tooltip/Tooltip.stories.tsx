import type { Meta, Story } from '@storybook/react'
import type { TooltipProps } from './Tooltip'
import { RiInformationLine as IconInfo, RiLinksLine as IconLink } from 'react-icons/ri'
import Tooltip from './Tooltip'

export default {
    title: 'Components/Tooltip',
    component: Tooltip,
} as Meta

const Template: Story<TooltipProps> = (args) => {
    return (
        <div className="flex justify-center py-20">
            <Tooltip {...args}>
                <button className="block transition-color duration-100 text-gray-50 hover:text-white">
                    <IconInfo className="h-5 w-5" />
                </button>
            </Tooltip>
        </div>
    )
}

export const Base = Template.bind({})
Base.args = { content: 'Short content' }

export const Multiline = Template.bind({})
Multiline.args = {
    content:
        'This is the cumulative investments (or fiat) that you have invested in your cryptocurrency portfolio.',
}

export const WithMarkup = Template.bind({})
WithMarkup.args = {
    content: (
        <div>
            <p className="font-medium">More information</p>
            <div className="flex w-full items-center mt-1">
                <IconInfo />
                <p className="pl-1">hello world</p>
            </div>
        </div>
    ),
}

export const Interactive = Template.bind({})
Interactive.args = {
    interactive: true,
    content: (
        <div>
            <p className="font-medium">Link to resource</p>
            <a
                href="https://maybe.co"
                target="_blank"
                rel="noreferrer"
                className="flex w-full items-center text-teal mt-1"
            >
                <IconLink />
                <p className="pl-1">hello world</p>
            </a>
        </div>
    ),
}

export const Delayed = Template.bind({})
Delayed.args = {
    delay: 500,
    content: 'Delayed information ⏰',
}
