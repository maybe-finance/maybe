import type { Story, Meta } from '@storybook/react'
import type { TakeoverProps } from './Takeover'
import * as React from 'react'

import Takeover from './Takeover'
import { Button } from '../../'

export default {
    title: 'Components/Takeover',
    component: Takeover,
    parameters: {
        controls: { include: ['as'] },
    },
} as Meta

export const Base: Story<TakeoverProps> = (args) => {
    const [isOpen, setIsOpen] = React.useState(false)

    return (
        <div className="h-48 flex items-center justify-center">
            <Button onClick={() => setIsOpen(true)}>Open Takeover</Button>
            <Takeover {...args} open={isOpen} onClose={() => setIsOpen(false)}>
                <div className="flex justify-center w-full pt-8 text-white">Press ESC to close</div>
            </Takeover>
        </div>
    )
}
