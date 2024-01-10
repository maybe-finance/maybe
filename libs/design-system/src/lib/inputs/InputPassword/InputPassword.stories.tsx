import type { Story, Meta } from '@storybook/react'
import type { InputPasswordProps } from '..'
import InputStories from '../Input/Input.stories'

import { FormGroup } from '../../FormGroup'
import { InputPassword } from '..'
import React, { useState } from 'react'

const inheritedArgTypes = InputStories.argTypes || {}
delete inheritedArgTypes.type
delete inheritedArgTypes.fixedLeftOverride
delete inheritedArgTypes.fixedRightOverride
delete inheritedArgTypes.colorHint

export default {
    title: 'Components/Inputs/InputPassword',
    component: InputPassword,
    parameters: {
        controls: {
            exclude: ['className', 'labelClassName', 'onValueChange', 'passwordComplexity'],
        },
    },
    argTypes: {
        ...inheritedArgTypes,
    },
    args: {
        label: 'Password',
    },
} as Meta

const Template: Story<InputPasswordProps> = (args) => {
    const [value, setValue] = useState<string>('')

    return (
        <FormGroup className="w-96 h-40">
            <InputPassword
                {...args}
                value={value}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setValue(e.target.value)}
            />
        </FormGroup>
    )
}

export const Base = Template.bind({})
