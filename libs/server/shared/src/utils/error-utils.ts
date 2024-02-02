import type { SharedType } from '@maybe-finance/shared'
import type { AxiosError } from 'axios'
import { Prisma } from '@prisma/client'
import axios from 'axios'

type PrismaError =
    | Prisma.PrismaClientKnownRequestError
    | Prisma.PrismaClientUnknownRequestError
    | Prisma.PrismaClientRustPanicError
    | Prisma.PrismaClientInitializationError
    | Prisma.PrismaClientValidationError

// Current no simple `isPrismaError()` method provided, so we must check all Class interfaces
function isPrismaError(error: unknown): error is PrismaError {
    return (
        error instanceof Prisma.PrismaClientKnownRequestError ||
        error instanceof Prisma.PrismaClientUnknownRequestError ||
        error instanceof Prisma.PrismaClientRustPanicError ||
        error instanceof Prisma.PrismaClientInitializationError ||
        error instanceof Prisma.PrismaClientValidationError
    )
}

export function isTellerError(err: unknown): err is SharedType.AxiosTellerError {
    if (!err) return false
    if (!axios.isAxiosError(err)) return false
    if (typeof err.response?.data !== 'object') return false

    const { data } = err.response
    return 'code' in data.error && 'message' in data.error
}

export function parseError(error: unknown): SharedType.ParsedError {
    if (axios.isAxiosError(error)) {
        return parseAxiosError(error)
    }

    if (isPrismaError(error)) {
        return parsePrismaError(error)
    }

    if (error instanceof Error) {
        return parseJSError(error)
    }

    if (typeof error === 'string') {
        return {
            message: error,
        }
    }

    if (typeof error === 'number') {
        return {
            message: error.toString(),
        }
    }

    return {
        message: '[unknown-error] Unable to parse',
        metadata: error,
    }
}

function parseAxiosError(error: AxiosError): SharedType.ParsedError {
    return {
        message: error.message,
        statusCode: error.response ? error.response.status.toString() : '500',
        metadata: error.response ? error.response.data : undefined,
        stackTrace: error.stack,
        sentryContexts: {
            'axios error': error.response?.data,
        },
    }
}

function parseJSError(error: Error): SharedType.ParsedError {
    return {
        message: error.message,
        stackTrace: error.stack,
    }
}

function parsePrismaError(error: PrismaError): SharedType.ParsedError {
    return {
        message: `[prisma-error] name=${error.name} message=${error.message}`,
        stackTrace: error.stack,
    }
}
