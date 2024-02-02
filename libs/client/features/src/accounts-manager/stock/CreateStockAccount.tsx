import { useAccountApi } from '@maybe-finance/client/shared'
import { Button, Dialog, Input } from '@maybe-finance/design-system'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { RiAddLine } from 'react-icons/ri'

type CreateStockAccountProps = {
    name: string | null
}

export default function CreateStockAccount() {
    const {
        register,
        handleSubmit,
        formState: { isSubmitting, isValid },
        // STOCKTODO - Fix UpdateVehicleFields
    } = useForm<CreateStockAccountProps>({
        mode: 'onChange',
    })

    const [isOpen, setIsOpen] = useState<boolean>(false)

    const { useCreateAccount } = useAccountApi()
    const createAccount = useCreateAccount()

    // STOCKTODO : Create a type for this
    async function onSubmit({ name }: CreateStockAccountProps) {
        setIsOpen(false)

        // STOCKTODO - Figure out a way to get the value from <Input/> to `name` here
        await createAccount.mutateAsync({
            type: 'INVESTMENT',
            categoryUser: 'investment',
            name: name,
        })
    }

    return (
        <>
            <Button className="h-10" onClick={() => setIsOpen(true)}>
                <RiAddLine size={20} />
            </Button>
            <Dialog isOpen={isOpen} onClose={() => setIsOpen(false)}>
                <form onSubmit={handleSubmit(onSubmit)} data-testid="create-stock-account-form">
                    <Dialog.Title>Create Investment Account</Dialog.Title>
                    <Dialog.Content>
                        <div className="space-y-3">
                            <Input type="text" label="Account name" {...register('name')} />
                        </div>
                    </Dialog.Content>
                    <Dialog.Actions>
                        <Button type="submit" fullWidth disabled={isSubmitting || !isValid}>
                            Create Account
                        </Button>
                    </Dialog.Actions>
                </form>
            </Dialog>
        </>
    )
}
