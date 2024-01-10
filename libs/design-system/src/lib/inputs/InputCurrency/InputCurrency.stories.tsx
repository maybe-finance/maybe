import type { Story, Meta } from '@storybook/react'
import type { InputCurrencyProps } from '..'
import InputStories from '../Input/Input.stories'

import { FormGroup } from '../../FormGroup'
import { InputCurrency } from '..'
import React, { useState } from 'react'

const inheritedArgTypes = InputStories.argTypes || {}
delete inheritedArgTypes.type
delete inheritedArgTypes.fixedLeftOverride
delete inheritedArgTypes.fixedRightOverride

export default {
    title: 'Components/Inputs/InputCurrency',
    component: InputCurrency,
    parameters: {
        controls: { exclude: ['className', 'labelClassName', 'onValueChange'] },
    },
    argTypes: {
        ...inheritedArgTypes,
    },
    args: {
        label: 'Currency',
        placeholder: 'Amount',
    },
} as Meta

const Template: Story<InputCurrencyProps> = (args) => {
    const [value, setValue] = useState<number | null>(null)

    return (
        <FormGroup className="w-60">
            <InputCurrency {...args} value={value} onChange={setValue} />
        </FormGroup>
    )
}

export const Base = Template.bind({})

export const WithColorHint = Template.bind({})
WithColorHint.args = { colorHint: 'cyan' }
