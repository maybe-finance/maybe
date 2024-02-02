import {
    useAccountApi,
    useAccountContext,
    type UpdateStockFields,
    type UpdateVehicleFields,
} from '@maybe-finance/client/shared'
import { Button, Dialog, Input, Listbox } from '@maybe-finance/design-system'
import { DateUtil } from '@maybe-finance/shared'
import { useForm } from 'react-hook-form'
import { AccountValuationFormFields } from '../AccountValuationFormFields'
import { useState } from 'react'
import { RiAddLine } from 'react-icons/ri'
import CreateStockAccount from './CreateStockAccount'

type Props = {
    mode: 'update'
    defaultValues: UpdateStockFields
    onSubmit(data: UpdateStockFields): void
}

export default function StockForm({ mode, defaultValues, onSubmit }: Props) {
    const {
        register,
        control,
        handleSubmit,
        watch,
        formState: { errors, isSubmitting, isValid },
    } = useForm<UpdateStockFields>({
        mode: 'onChange',
        defaultValues,
    })

    const startDate = watch('startDate')
    const currentBalanceEditable = !startDate || !DateUtil.isToday(startDate)

    const [stockSymbol, setStockSymbol] = useState<string | null>(null)
    const [account, setAccount] = useState<string | null>(null)

    const { useAccounts } = useAccountApi()
    const { data: accountsData } = useAccounts()

    const stockAccountsList = accountsData?.accounts.filter(
        (account) => account.type === 'INVESTMENT'
    )

    return (
        <form onSubmit={handleSubmit(onSubmit)} data-testid="stock-form">
            <section className="space-y-4 mb-8">
                <h6 className="text-white uppercase">Details</h6>
                <div className="space-y-4">
                    {/* 
                        STOCKTODO - Change this to a drop down where a pre-existing stock-account can be selected or a new stock account can be created

                        Also make sure this this is submitted to the form. There was a ...register('make', { required: true }) here
                    */}
                    {/* STOCKTODO - Create currently selected stock state */}
                    <div className="flex flex-row gap-2 items-end">
                        {stockAccountsList && (
                            <Listbox value={account} onChange={setAccount} className="flex-1">
                                <Listbox.Button label="Investment account"></Listbox.Button>
                                <Listbox.Options>
                                    {stockAccountsList?.map((account) => (
                                        // STOCKTODO - Figure out the correct account value - probably will be the symbol
                                        <Listbox.Option key={account.id} value={account.name}>
                                            {account.name}
                                        </Listbox.Option>
                                    ))}
                                </Listbox.Options>
                            </Listbox>
                        )}
                        {/* STOCKTODO - When this button is clicked, go to the modal to create a new account */}
                        <CreateStockAccount />
                    </div>

                    {/* STOCKTODO - Change to to a drop down where all the stocks will be listed and can be chosen by their ticker names */}
                    {/* <Listbox value={stockSymbol} onChange={setStockSymbol}>
                        <Listbox.Button label="Investment account"></Listbox.Button>
                        <Listbox.Options>
                            {stocksList.map((stock) => (
                                // STOCKTODO - Figure out the correct stock value - probably will be the symbol
                                <Listbox.Option key={stock.key} value={stock.symbol}>
                                    {stock.name}
                                </Listbox.Option>
                            ))}
                        </Listbox.Options>
                    </Listbox> */}
                </div>
            </section>

            {mode === 'update' && (
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
                {mode === 'update' ? 'Add stock' : 'Update'}
            </Button>
        </form>
    )
}
