import type { CreateStockFields, UpdateVehicleFields } from '@maybe-finance/client/shared'
import { Button, Input, Listbox } from '@maybe-finance/design-system'
import { DateUtil } from '@maybe-finance/shared'
import { useForm } from 'react-hook-form'
import { AccountValuationFormFields } from '../AccountValuationFormFields'

// STOCKTODO - Change CreateVehicleFields and UpdateVehicleFields
type Props = {
    mode: 'create'
    defaultValues: CreateStockFields
    onSubmit(data: CreateStockFields): void
}
// | {
//       mode: 'update'
//       defaultValues: UpdateVehicleFields
//       onSubmit(data: UpdateVehicleFields): void
//   }

export default function StockForm({ mode, defaultValues, onSubmit }: Props) {
    const {
        register,
        control,
        handleSubmit,
        watch,
        formState: { errors, isSubmitting, isValid },
        // STOCKTODO - Fix UpdateVehicleFields
    } = useForm<CreateStockFields & UpdateVehicleFields>({
        mode: 'onChange',
        defaultValues,
    })

    const startDate = watch('startDate')
    const currentBalanceEditable = !startDate || !DateUtil.isToday(startDate)

    return (
        <form onSubmit={handleSubmit(onSubmit)} data-testid="stock-form">
            <section className="space-y-4 mb-8">
                <h6 className="text-white uppercase">Details</h6>
                <div className="space-y-4">
                    {/* 
                        STOCKTODO - Change this to a drop down where a pre-existing stock-account can be selected or a new stock account can be created

                        Also make sure this this is submitted to the form. There was a ...register('make', { required: true }) here
                    */}
                    {/* <Input
                        type="text"
                        label="Make"
                        placeholder="Enter make"
                        error={errors.make && 'Make is required'}
                        {...register('make', { required: true })}
                    /> */}
                    {/* STOCKTODO - Create currently selected stock state */}
                    <Listbox value={stock} onChange={setStock}>
                        <Listbox.Button label="Investment account"></Listbox.Button>
                        <Listbox.Options>
                            {stockAccountsList.map((account) => (
                                // STOCKTODO - Figure out the correct account value - probably will be the symbol
                                <Listbox.Option key={account.account_id} value={account.name}>
                                    {account.name}
                                </Listbox.Option>
                            ))}
                        </Listbox.Options>
                    </Listbox>

                    {/* STOCKTODO - Change to to a drop down where all the stocks will be listed and can be chosen by their ticker names */}
                    <Input
                        type="text"
                        label="Model"
                        placeholder="Enter model"
                        error={errors.model && 'Model is required'}
                        {...register('model', { required: true })}
                    />
                </div>
            </section>

            {mode === 'create' && (
                <section className="space-y-4">
                    <h6 className="text-white uppercase">Valuation</h6>
                    <div>
                        {/* 
                            STOCKTODO - Figure out a way to get the necessary properties here
                            1. Purchase Date
                            2. Total Purchase Value
                            3. Number of Shares 
                        */}
                        <AccountValuationFormFields
                            control={control}
                            currentBalanceEditable={currentBalanceEditable}
                        />
                    </div>
                </section>
            )}

            <Button
                type="submit"
                fullWidth
                disabled={isSubmitting || !isValid}
                data-testid="stock-form-submit"
            >
                {mode === 'create' ? 'Add stock' : 'Update'}
            </Button>
        </form>
    )
}
