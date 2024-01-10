import superjson from 'superjson'
import type { Prisma } from '@prisma/client'
import { Decimal } from 'decimal.js'
import { DateTime } from 'luxon'

superjson.registerCustom<Decimal | Prisma.Decimal, string>(
    {
        isApplicable: (v): v is Decimal | Prisma.Decimal => Decimal.isDecimal(v),
        serialize: (d) => d.toJSON(),
        deserialize: (s) => new Decimal(s),
    },
    'Decimal'
)

superjson.registerCustom<DateTime, string>(
    {
        isApplicable: (v): v is DateTime => DateTime.isDateTime(v),
        serialize: (dt) => dt.toISO(),
        deserialize: (s) => DateTime.fromISO(s),
    },
    'DateTime'
)

export default superjson
