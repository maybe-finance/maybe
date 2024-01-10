import { Prisma } from '@prisma/client'
import { Decimal } from 'decimal.js'
import { DateTime } from 'luxon'
import superjson from './superjson'

describe('superjson', () => {
    it.each`
        type                | value
        ${`BigInt`}         | ${BigInt(123)}
        ${`Decimal`}        | ${new Decimal(1.23)}
        ${`Prisma.Decimal`} | ${new Prisma.Decimal(1.23)}
        ${`Date`}           | ${new Date()}
        ${`DateTime`}       | ${DateTime.now()}
    `('can serialize $type', ({ type, value }) => {
        const s = superjson.stringify(value)
        const v = superjson.parse(s)

        // Prisma.Decimal always gets converted to a decimal.js Decimal
        // so we need to special case that equality check
        expect(v).toEqual(type === 'Prisma.Decimal' ? new Decimal(value) : value)
    })
})
