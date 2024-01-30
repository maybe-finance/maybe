import { useAccountApi } from '@maybe-finance/client/shared'
import { Button, Dialog, Input } from '@maybe-finance/design-system'
import { useState } from 'react'
import { RiAddLine } from 'react-icons/ri'

export default function CreateStockAccount() {
    const [isOpen, setIsOpen] = useState<boolean>(false)

    const { useCreateAccount } = useAccountApi()
    const createAccount = useCreateAccount()

    async function clickHandler() {
        setIsOpen(false)

        await createAccount.mutateAsync({
            type: 'INVESTMENT',
            categoryUser: 'investment',
            name: 'Test Account',
        })
    }

    return (
        <>
            <Button className="h-10" onClick={() => setIsOpen(true)}>
                <RiAddLine size={20} />
            </Button>
            <Dialog isOpen={isOpen} onClose={() => setIsOpen(false)}>
                <Dialog.Title>Create Investment Account</Dialog.Title>
                <Dialog.Content>
                    <div className="space-y-3">
                        <Input type="text" label="Account name" />
                    </div>
                </Dialog.Content>
                <Dialog.Actions>
                    <Button type="button" onClick={clickHandler} fullWidth>
                        Create Account
                    </Button>
                </Dialog.Actions>
            </Dialog>
        </>
    )
}
