import { z } from 'zod'

export const InvestmentTransactionCategorySchema = z.enum([
    'buy',
    'sell',
    'dividend',
    'transfer',
    'tax',
    'fee',
    'cancel',
    'other',
])
