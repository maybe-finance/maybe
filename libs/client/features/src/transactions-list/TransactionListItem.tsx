import { useState } from 'react'
import Image from 'next/legacy/image'
import {
    RiAddLine as PlusIcon,
    RiEyeLine,
    RiEyeOffLine,
    RiMore2Fill,
    RiPencilLine,
    RiSubtractLine as MinusIcon,
    RiTimeLine as PendingIcon,
} from 'react-icons/ri'
import { NumberUtil, TransactionUtil } from '@maybe-finance/shared'
import { BrowserUtil, useTransactionApi } from '@maybe-finance/client/shared'
import type { SharedType } from '@maybe-finance/shared'
import { Button, DialogV2, Listbox, Menu } from '@maybe-finance/design-system'
import classNames from 'classnames'
import { type InfiniteData, useQueryClient } from '@tanstack/react-query'
import toast from 'react-hot-toast'
import { Controller, useForm } from 'react-hook-form'
import type { TransactionType } from '@prisma/client'

const types = {
    INCOME: 'Income',
    EXPENSE: 'Expense',
    TRANSFER: 'Transfer',
    PAYMENT: 'Debt payment',
}

export function TransactionListItem({
    transaction,
}: {
    transaction: SharedType.AccountTransactionResponse['transactions'][0]
}) {
    const queryClient = useQueryClient()
    const { useUpdateTransaction } = useTransactionApi()
    const [editTxn, setEditTxn] = useState(false)

    // Optimistically updates transaction, see https://github.com/TanStack/query/discussions/848#discussioncomment-473919
    const updateTxn = useUpdateTransaction({
        async onMutate(updatedTxnData) {
            const queryKey = ['accounts', transaction.accountId, 'transactions']
            await queryClient.cancelQueries({ queryKey })
            const previousTxns = queryClient.getQueryData(queryKey)

            // Finds transaction in pages and optimistically updates
            queryClient.setQueryData<InfiniteData<SharedType.AccountTransactionResponse>>(
                queryKey,
                (data) => {
                    if (data) {
                        return {
                            ...data,
                            pages: data.pages.map((page) => ({
                                ...page,
                                transactions: page.transactions.map((txn) => {
                                    return txn.id === transaction.id
                                        ? {
                                              ...txn,
                                              ...updatedTxnData.data,
                                              type: updatedTxnData.data.typeUser
                                                  ? updatedTxnData.data.typeUser
                                                  : txn.type,
                                              category: updatedTxnData.data.categoryUser
                                                  ? updatedTxnData.data.categoryUser
                                                  : txn.category,
                                          }
                                        : txn
                                }),
                            })),
                        }
                    }

                    return data
                }
            )

            return { previousTxns }
        },
        onSettled() {
            queryClient.invalidateQueries(['users', 'insights'])
            setEditTxn(false)
        },
        onSuccess() {
            toast.success('Transaction updated!')
        },
        onError(err, newTxn, context) {
            toast.error('Transaction failed to update.')
            queryClient.setQueryData(
                ['accounts', transaction.accountId, 'transactions'],
                (context as any).previousTxns
            )
        },
    })

    const { control, handleSubmit } = useForm({
        defaultValues: {
            categoryUser: transaction.category,
            typeUser: transaction.type,
        },
    })

    const isPositive = transaction.amount.isPositive()

    const subtext = [
        transaction.pending && 'Pending',
        transaction.excluded && 'Excluded from insights',
    ].filter((t) => typeof t === 'string')

    return (
        <li className="flex flex-wrap items-center justify-between" key={transaction.id}>
            <div className="flex items-center my-2">
                <div className="relative">
                    {transaction.category !== 'TRANSFER' ? (
                        <div className="relative h-8 w-8 sm:w-12 sm:h-12 bg-gray-400 rounded-xl overflow-hidden">
                            <Image
                                loader={BrowserUtil.enhancerizerLoader}
                                src={JSON.stringify({
                                    kind: 'merchant',
                                    ...(transaction.merchantName
                                        ? {
                                              name: transaction.merchantName,
                                          }
                                        : {}),
                                    description: transaction.name,
                                })}
                                layout="fill"
                                sizes="48px, 64px, 96px, 128px"
                                onError={({ currentTarget }) => {
                                    // Fail gracefully and hide image
                                    currentTarget.onerror = null
                                    currentTarget.style.display = 'none'
                                }}
                            />
                            {transaction.excluded && (
                                <div className="absolute flex items-center justify-center w-full h-full z-10 bg-gray-800 bg-opacity-50">
                                    <RiEyeOffLine className="w-5 h-5 text-gray-50" />
                                </div>
                            )}
                        </div>
                    ) : (
                        <div
                            className={`flex items-center justify-center w-12 h-12 rounded-xl bg-opacity-10 ${
                                isPositive ? 'bg-teal' : 'bg-red'
                            }`}
                        >
                            {isPositive ? (
                                <PlusIcon className="w-5 h-5 text-teal-500" />
                            ) : (
                                <MinusIcon className="w-5 h-5 text-red-500" />
                            )}
                        </div>
                    )}
                    {transaction.pending && (
                        <div className="absolute flex items-center justify-center -bottom-1 -right-2 w-5 h-5 box-border rounded-full border-2 border-gray-700 bg-gray-500">
                            <PendingIcon className="w-3.5 h-3.5" />
                        </div>
                    )}
                </div>
                <div className="ml-4 text-sm sm:text-base">
                    <div title={transaction.name} className="w-[100px] lg:w-auto truncate">
                        {transaction.merchantName || transaction.name}
                    </div>
                    <div className="text-sm text-gray-200">
                        {subtext.length > 0 && <em>{subtext.join(' • ')}</em>}
                    </div>
                </div>
            </div>
            <div className="flex items-center gap-2">
                <div className="hidden sm:flex xl:hidden items-center justify-self-end">
                    <div
                        className={classNames(
                            'w-1 h-3 mr-3 rounded-full',
                            isPositive ? 'bg-teal' : 'bg-red',
                            transaction.type === 'INCOME'
                                ? 'bg-green'
                                : transaction.type === 'EXPENSE'
                                ? 'bg-red'
                                : transaction.type === 'TRANSFER'
                                ? 'bg-teal'
                                : 'bg-orange'
                        )}
                    ></div>
                    {types[transaction.type]}{' '}
                    <span className="text-gray-50 inline-block mx-1">/</span>
                    {transaction.category}
                </div>
                <div className="hidden xl:flex items-center justify-self-end gap-3">
                    <Listbox
                        value={transaction.type}
                        onChange={(type) => {
                            updateTxn.mutate({
                                id: transaction.id,
                                data: { typeUser: type },
                            })
                        }}
                    >
                        <Listbox.Button className="bg-transparent">
                            <div className="flex items-center gap-3">
                                <div
                                    className={classNames(
                                        'w-1 h-3 rounded-full',
                                        transaction.type === 'INCOME'
                                            ? 'bg-green'
                                            : transaction.type === 'EXPENSE'
                                            ? 'bg-red'
                                            : transaction.type === 'TRANSFER'
                                            ? 'bg-teal'
                                            : 'bg-orange'
                                    )}
                                ></div>
                                {types[transaction.type]}
                            </div>
                        </Listbox.Button>
                        <Listbox.Options>
                            {Object.keys(types).map((type) => (
                                <Listbox.Option key={type} value={type}>
                                    {types[type as TransactionType]}
                                </Listbox.Option>
                            ))}
                        </Listbox.Options>
                    </Listbox>

                    <Listbox
                        value={transaction.category}
                        onChange={(category) => {
                            updateTxn.mutate({
                                id: transaction.id,
                                data: { categoryUser: category },
                            })
                        }}
                    >
                        <Listbox.Button>{transaction.category}</Listbox.Button>
                        <Listbox.Options>
                            {TransactionUtil.CATEGORIES.map((category) => (
                                <Listbox.Option key={category} value={category}>
                                    {category}
                                </Listbox.Option>
                            ))}
                        </Listbox.Options>
                    </Listbox>
                </div>
                <div
                    className={`sm:min-w-[100px] text-sm sm:text-base text-right font-semibold tabular-nums ${
                        isPositive ? 'text-teal-500' : 'text-red-500'
                    }`}
                >
                    {NumberUtil.format(transaction.amount, 'currency')}
                </div>
                <div>
                    <Menu>
                        <Menu.Button variant="icon">
                            <RiMore2Fill className="text-gray-50" />
                        </Menu.Button>
                        <Menu.Items placement="bottom-end">
                            <Menu.Item
                                icon={transaction.excluded ? <RiEyeLine /> : <RiEyeOffLine />}
                                onClick={() =>
                                    updateTxn.mutate({
                                        id: transaction.id,
                                        data: { excluded: !transaction.excluded },
                                    })
                                }
                            >
                                {transaction.excluded
                                    ? 'Include in insights'
                                    : 'Exclude from insights'}
                            </Menu.Item>

                            <Menu.Item
                                icon={<RiPencilLine />}
                                onClick={() => setEditTxn(true)}
                                className="xl:hidden"
                            >
                                Edit Transaction
                            </Menu.Item>
                            <DialogV2
                                title="Edit transaction"
                                open={editTxn}
                                className="mx-2"
                                onClose={() => setEditTxn(false)}
                            >
                                <form
                                    className="space-y-6"
                                    onSubmit={handleSubmit(({ typeUser, categoryUser }) => {
                                        updateTxn.mutate({
                                            id: transaction.id,
                                            data: {
                                                typeUser,
                                                categoryUser,
                                            },
                                        })
                                    })}
                                >
                                    <Controller
                                        name="typeUser"
                                        control={control}
                                        render={({ field }) => (
                                            <Listbox {...field}>
                                                <Listbox.Button label="Type">
                                                    {types[field.value]}
                                                </Listbox.Button>
                                                <Listbox.Options>
                                                    {Object.keys(types).map((type) => (
                                                        <Listbox.Option key={type} value={type}>
                                                            {types[type as TransactionType]}
                                                        </Listbox.Option>
                                                    ))}
                                                </Listbox.Options>
                                            </Listbox>
                                        )}
                                    />

                                    <Controller
                                        name="categoryUser"
                                        control={control}
                                        render={({ field }) => (
                                            <Listbox {...field}>
                                                <Listbox.Button label="Category">
                                                    {field.value}
                                                </Listbox.Button>
                                                <Listbox.Options>
                                                    {TransactionUtil.CATEGORIES.map((category) => (
                                                        <Listbox.Option
                                                            key={category}
                                                            value={category}
                                                        >
                                                            {category}
                                                        </Listbox.Option>
                                                    ))}
                                                </Listbox.Options>
                                            </Listbox>
                                        )}
                                    />

                                    <Button type="submit" fullWidth>
                                        Save
                                    </Button>
                                </form>
                            </DialogV2>
                        </Menu.Items>
                    </Menu>
                </div>
            </div>
        </li>
    )
}
