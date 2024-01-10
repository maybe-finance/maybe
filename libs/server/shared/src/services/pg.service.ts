import { Prisma } from '@prisma/client'
import { Pool, types } from 'pg'
import type { Logger } from 'winston'

// convert date to string
types.setTypeParser(types.builtins.DATE, (val) => val)

// convert bigint
types.setTypeParser(types.builtins.INT8, (val) => {
    return val == null ? null : BigInt(val)
})

// convert numeric to Decimal.js
types.setTypeParser(types.builtins.NUMERIC, (val) => {
    return val == null ? null : new Prisma.Decimal(val)
})

export class PgService {
    private readonly _pool: Pool

    constructor(private readonly logger: Logger, databaseUrl = process.env.NX_DATABASE_URL) {
        this._pool = new Pool({
            connectionString: databaseUrl,
        })

        this._pool.on('error', (err, _client) => {
            console.error('[pg.error]', err)
        })
    }

    get pool() {
        return this._pool
    }
}
