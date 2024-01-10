import type { Logger } from 'winston'
import { DateTime, Duration } from 'luxon'
import type Redis from 'ioredis'
import { superjson } from '@maybe-finance/shared'

interface ICacheBackend {
    getItem<TValue>(key: string): Promise<TValue | null>
    setItem<TValue>(key: string, value: TValue, exp: Duration): Promise<void>
}

export class MemoryCacheBackend implements ICacheBackend {
    constructor(private readonly cache: Record<string, { value: any; exp: DateTime }> = {}) {}

    async getItem<TValue>(key: string): Promise<TValue | null> {
        const item = this.cache[key]
        if (item == null) return null
        return item.exp.diffNow() >= Duration.fromMillis(0) ? item.value : null
    }

    async setItem<TValue>(key: string, value: TValue, exp: Duration): Promise<void> {
        this.cache[key] = { value, exp: DateTime.now().plus(exp) }
    }
}

export class RedisCacheBackend implements ICacheBackend {
    constructor(private readonly redis: Redis) {}

    async getItem<TValue>(key: string): Promise<TValue | null> {
        const rawValue = await this.redis.get(this.key(key))
        return rawValue == null ? null : superjson.parse<TValue>(rawValue)
    }

    async setItem<TValue>(key: string, value: TValue, exp: Duration): Promise<void> {
        await this.redis.setex(this.key(key), exp.as('seconds'), superjson.stringify(value))
    }

    private key(key: string) {
        return `cache:${key}`
    }
}

export class CacheService {
    constructor(
        private readonly logger: Logger,
        private readonly cache: ICacheBackend,
        private readonly defaultExpiration = Duration.fromObject({ minutes: 15 })
    ) {}

    async getOrAdd<K extends string, V>(
        key: K,
        valueFn: V | ((_key: K) => Promise<V>),
        exp?: Duration
    ): Promise<V> {
        // first check for non-expired cached value
        const existingValue = await this.cache.getItem<V>(key)
        if (existingValue) {
            this.logger.debug(`HIT k="${key}"`)
            return existingValue
        }

        this.logger.debug(`MISS k="${key}"`)

        // compute value to cache
        const newValue = typeof valueFn === 'function' ? await (valueFn as any)(key) : valueFn
        await this.cache.setItem(key, newValue, exp || this.defaultExpiration)
        this.logger.debug(`SET k="${key}"`)

        return newValue
    }
}
