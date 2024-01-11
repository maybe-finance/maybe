/**
 * @returns redis retry strategy
 */
export function redisRetryStrategy({
    maxAttempts = Infinity,
    delayMs = 2_000,
    backoff = 'linear',
}: {
    maxAttempts?: number
    delayMs?: number
    backoff?: 'linear' | 'exponential'
} = {}) {
    return (attempt: number) => {
        const delay = backoff === 'linear' ? delayMs : delayMs * attempt
        return attempt <= maxAttempts ? delay : null
    }
}

/**
 * wrapper for executing sync pattern, basically a try-catch-else-finally pattern
 */
export function useSync<TEntity>({
    onStart,
    sync,
    onSyncError,
    onSyncSuccess,
    onEnd,
}: {
    onStart?: (entity: TEntity) => Promise<any>
    sync: (entity: TEntity) => Promise<any>
    onSyncError: (entity: TEntity, error: unknown) => Promise<any>
    onSyncSuccess: (entity: TEntity) => Promise<any>
    onEnd?: (entity: TEntity) => Promise<any>
}): (entity: TEntity) => Promise<void> {
    return async (entity: TEntity) => {
        await onStart?.(entity)

        await tryCatchElseFinally(
            () => sync(entity),
            (error) => onSyncError(entity, error),
            () => onSyncSuccess(entity),
            () => onEnd?.(entity) ?? Promise.resolve()
        )
    }
}

async function tryCatchElseFinally(
    _try: () => Promise<void>,
    _catch: (error: unknown) => Promise<void>,
    _else: () => Promise<void>,
    _finally: () => Promise<void>
): Promise<void> {
    try {
        let success = true

        try {
            await _try()
        } catch (error) {
            success = false
            await _catch(error)
        }

        if (success) {
            await _else()
        }
    } finally {
        await _finally()
    }
}

// Temporary until Prisma Client Extensions work better
export type SignerConfig = {
    cdnUrl: string
    pubKeyId: string
    privKey: string
}
