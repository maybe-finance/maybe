import { DateTime } from 'luxon'
import { useRouter } from 'next/router'

export function useQueryParam(key: string, type: 'string'): string | undefined
export function useQueryParam(key: string, type: 'string[]'): string[]
export function useQueryParam(key: string, type: 'number'): number | undefined
export function useQueryParam(key: string, type: 'date'): Date | undefined
export function useQueryParam(key: string, type: 'boolean'): boolean
export function useQueryParam(
    key: string,
    type: 'string' | 'string[]' | 'number' | 'date' | 'boolean'
): string | string[] | number | Date | boolean | undefined {
    const { query, isReady } = useRouter()

    if (!isReady) return undefined

    const value = query[key]

    switch (type) {
        case 'string':
            return Array.isArray(value) ? value[0] : value
        case 'string[]':
            return Array.isArray(value) ? value : value ? [value] : []
        case 'number':
            if (!value || typeof value !== 'string') return undefined
            return value ? parseInt(value) : undefined
        case 'date': {
            if (!value || typeof value !== 'string') return undefined
            const date = DateTime.fromISO(value)
            return date.isValid ? date.toISODate() : undefined
        }
        case 'boolean':
            if (!value || typeof value !== 'string') return false
            return value ? ['y', 'yes', 'true', '1'].includes(value.toLowerCase().trim()) : false
        default:
            throw Error(`unhandled param type: ${type}`)
    }
}
