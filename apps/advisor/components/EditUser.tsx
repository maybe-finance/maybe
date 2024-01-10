import { Button, DialogV2, Input, InputCurrency, Listbox } from '@maybe-finance/design-system'
import type { User } from '@prisma/client'
import { Controller, useForm } from 'react-hook-form'
import { toast } from 'react-hot-toast'
import { trpc } from '../lib/trpc'
import { taxMap } from '../lib/util'

type EditUserProps = {
    user: Pick<User, 'id' | 'dependents' | 'taxStatus' | 'incomeType' | 'grossIncome'>
    isOpen: boolean
    onClose(): void
}
export default function EditUser({ user, isOpen, onClose }: EditUserProps) {
    const utils = trpc.useContext()
    const updateUser = trpc.advisor.users.update.useMutation({
        onSuccess() {
            toast.success('User saved')
            utils.advisor.users.get.invalidate()
            onClose()
        },
        onError() {
            toast.error('Failed to save user')
        },
    })

    const { id, taxStatus, incomeType, dependents, grossIncome } = user

    return (
        <DialogV2 open={isOpen} onClose={onClose} title="Edit User">
            <EditUserForm
                defaultValues={{ taxStatus, incomeType, dependents, grossIncome }}
                onSubmit={({ taxStatus, incomeType, dependents, grossIncome }) => {
                    updateUser.mutate({
                        userId: id,
                        taxStatus: taxStatus || null,
                        incomeType: incomeType || null,
                        dependents: dependents ? +dependents : null,
                        grossIncome: grossIncome || null,
                    })
                }}
            />
        </DialogV2>
    )
}

type FormFields = Pick<User, 'taxStatus' | 'incomeType' | 'dependents' | 'grossIncome'>
type Props = {
    defaultValues: FormFields
    onSubmit(data: FormFields): void
}
function EditUserForm({ defaultValues, onSubmit }: Props) {
    const { handleSubmit, control, register } = useForm({ defaultValues })
    return (
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-3">
            <Input
                {...register('dependents')}
                type="number"
                className="bg-transparent"
                label="Number of kids"
            />

            <Controller
                name="taxStatus"
                control={control}
                render={({ field }) => {
                    return (
                        <>
                            <Listbox {...field}>
                                <Listbox.Button label="Tax filing status">
                                    {taxMap[(field.value as string) ?? '']}
                                </Listbox.Button>
                                <Listbox.Options>
                                    {Object.entries(taxMap).map(([key, title]) => (
                                        <Listbox.Option value={key} key={key}>
                                            {title}
                                        </Listbox.Option>
                                    ))}
                                </Listbox.Options>
                            </Listbox>
                        </>
                    )
                }}
            />

            <Controller
                name="grossIncome"
                control={control}
                render={({ field }) => {
                    return (
                        <InputCurrency
                            {...field}
                            allowNegative={false}
                            decimalScale={0}
                            label="Gross Annual Income"
                        />
                    )
                }}
            />

            <Input {...register('incomeType')} label="Income type" />

            <Button fullWidth type="submit">
                Save
            </Button>
        </form>
    )
}
