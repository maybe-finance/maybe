import { Button } from '@maybe-finance/design-system'
import React, { type Dispatch, type SetStateAction } from 'react'

export const DeveloperFastLogin = ({
    setEmail,
    setPassword,
    setIsValid,
}: {
    setEmail: Dispatch<SetStateAction<string>>
    setPassword: Dispatch<SetStateAction<string>>
    setIsValid: Dispatch<SetStateAction<boolean>>
}) => (
    <div className="flex mt-4 gap-10">
        <Button
            onClick={() => {
                setEmail('test@test.com')
                setPassword('Password1')
                setIsValid(true)
            }}
        >
            Test
        </Button>
        <Button
            onClick={() => {
                setEmail('john@john.com')
                setPassword('Password2')
                setIsValid(true)
            }}
        >
            John
        </Button>
        <Button
            onClick={() => {
                setEmail('jane@jane.com')
                setPassword('Password3')
                setIsValid(true)
            }}
        >
            Jane
        </Button>
    </div>
)
