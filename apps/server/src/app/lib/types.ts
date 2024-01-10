import type { Response, Request, NextFunction } from 'express'

interface TypedRequest<T> extends Omit<Request, 'body'> {
    body: T
}

interface TypedResponse<T> extends Response {
    superjson(data: T): TypedResponse<T>
}

export type DefaultHandler<Req, Res> = (
    req: TypedRequest<Req>,
    res: TypedResponse<Res>,
    next: NextFunction
) => void

// GET requests have optional request type, mandatory response type
export type GetHandler<Res> = (
    req: TypedRequest<any>, // eslint-disable-line
    res: TypedResponse<Res>,
    next: NextFunction
) => void

// Aliases for semantics and convenience
export type PostHandler<Req, Res> = DefaultHandler<Req, Res>
export type PutHandler<Req, Res> = DefaultHandler<Req, Res>
export type DeleteHandler<Req, Res> = DefaultHandler<Req, Res>
