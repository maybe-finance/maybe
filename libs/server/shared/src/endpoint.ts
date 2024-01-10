import type { RequestHandler, Request, Response } from 'express'
import { z } from 'zod'

type EndpointSchema<TInput = unknown> = {
    parse: (input: any) => TInput
}

type EndpointResolverArgs<TContext, TInput> = {
    input: TInput
    ctx: TContext
    req: Request
}

type EndpointOnSuccess = <TOutput>(req: Request, res: Response, output: TOutput) => any

type EndpointWithInput<TContext, TInput, TOutput> = {
    input: EndpointSchema<TInput>
    authorize?(args: EndpointResolverArgs<TContext, TInput>): boolean | Promise<boolean>
    resolve(args: EndpointResolverArgs<TContext, TInput>): Promise<TOutput>
    onSuccess?: EndpointOnSuccess
}

type EndpointWithoutInput<TContext, TOutput> = Omit<
    EndpointWithInput<TContext, undefined, TOutput>,
    'input'
>

export class EndpointFactory<TContext> {
    constructor(
        private readonly options: {
            createContext: (req: Request, res: Response) => TContext | Promise<TContext>
            onSuccess?: EndpointOnSuccess
        }
    ) {}

    create<TInput, TOutput>(opts: EndpointWithInput<TContext, TInput, TOutput>): RequestHandler
    create<TOutput>(opts: EndpointWithoutInput<TContext, TOutput>): RequestHandler
    create<TInput, TOutput>(
        opts: EndpointWithInput<TContext, TInput, TOutput> | EndpointWithoutInput<TContext, TOutput>
    ): RequestHandler {
        const { authorize, resolve } = opts
        const input = 'input' in opts ? opts.input : undefined

        return async (req, res, next) => {
            let inputData: TInput | undefined
            try {
                inputData = input?.parse({ ...req.query, ...req.body })
            } catch (err) {
                console.error('input parse error', err)
                if (err instanceof z.ZodError) {
                    return res.status(400).json({ errors: err.format() })
                }
            }

            const ctx = await this.options.createContext(req, res)

            if (authorize && !(await authorize({ input: inputData as any, ctx, req }))) {
                return res.status(401).send('Unauthorized')
            }

            resolve({ input: inputData as any, ctx, req })
                .then((output) =>
                    opts.onSuccess
                        ? opts.onSuccess(req, res, output)
                        : this.options.onSuccess
                        ? this.options.onSuccess(req, res, output)
                        : res.status(200).json(output)
                )
                .catch(next)
        }
    }
}
