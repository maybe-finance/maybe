import { App } from 'aws-cdk-lib'
import { z } from 'zod'

const toStr = (v: number) => v.toString()

/**
 * Fargate compute capacity schema
 *
 * @see https://docs.aws.amazon.com/AmazonECS/latest/userguide/fargate-task-defs.html#fargate-tasks-size
 */
const fargateComputeSchema = z.union([
    z
        .object({
            cpu: z.literal(512),
            memory: z.enum(['1024', '2048', '3072', '4096']),
        })
        .strict(),
    z
        .object({
            cpu: z.literal(1024),
            memory: z.enum(['2048', '3072', '4096', '5120', '6144', '7168', '8192']),
        })
        .strict(),
    z
        .object({
            cpu: z.literal(2048),
            memory: z.enum(['4096', '5120', '6144', '7168', '8192', '9216', '10240']),
        })
        .strict(),
    z
        .object({
            cpu: z.literal(4096),
            memory: z.enum(['4096', '5120', '6144', '7168', '8192', '9216', '10240']),
        })
        .strict(),
])

const maybeAppSharedEnv = z
    .object({
        NX_API_URL: z.string(),
        NX_CDN_URL: z.string(),
        NODE_ENV: z.enum(['production', 'development']),
        NX_AUTH0_AUDIENCE: z.literal('https://maybe-finance-api/v1'),
        NX_PLAID_CLIENT_ID: z.literal('REPLACE_THIS'),
        NX_PLAID_ENV: z.string(),
        NX_FINICITY_PARTNER_ID: z.literal('REPLACE_THIS'),
        NX_FINICITY_ENV: z.enum(['sandbox', 'production']),
        NX_CLIENT_URL: z.string(),
        NX_CLIENT_URL_CUSTOM: z.string(),
        NX_ADVISOR_URL: z.string(),
        NX_AUTH0_DOMAIN: z.string(),
        NX_AUTH0_CUSTOM_DOMAIN: z.string(),
        NX_AUTH0_CLIENT_ID: z.string(),
        NX_AUTH0_MGMT_CLIENT_ID: z.string(),
        NX_SENTRY_ENV: z.string(),
        NX_POSTMARK_FROM_ADDRESS: z.string(),
        NX_STRIPE_PREMIUM_YEARLY_PRICE_ID: z.string().optional(),
        NX_STRIPE_PREMIUM_MONTHLY_PRICE_ID: z.string().optional(),
    })
    .strict()

const maybeAppSharedStackContext = z
    .object({
        PeeringCnxId: z.string().optional(),
        PeeringCnxCidr: z.string(),
        VPC: z
            .object({
                NATCount: z.number().lte(2),
                IPAllowList: z.string().array().max(20), // Limit to 20 addresses to avoid rule priority conflicts
            })
            .strict(),
        Redis: z
            .object({
                size: z.enum([
                    'cache.t4g.micro',
                    'cache.t4g.small',
                    'cache.t4g.medium',
                    'cache.m5.large',
                    'cache.m6g.large',
                    'cache.m6g.xlarge',
                    'cache.m6g.2xlarge',
                ]),
                count: z.number().lte(5),
            })
            .strict(),
        Cloudfront: z
            .object({
                CertificateArn: z.string(), // located in us-east-1 region
                CNAMES: z.string().array(),
            })
            .strict(),
        UploadOrigins: z.array(z.string()).min(1),
    })
    .strict()

const maybeAppServerStackContext = z.object({
    CertificateArn: z.string(),
    DesiredTaskCount: z.number(),
    WAFArn: z.string(),
    ComputeCapacity: fargateComputeSchema,
    Cloudfront: z
        .object({
            CNAMES: z.string().array(),
            CertificateArn: z.string(), // located in us-east-1 region
        })
        .strict(),
    Container: z
        .object({
            Env: z
                .object({
                    NX_CORS_ORIGINS: z.string(),
                    NX_MORGAN_LOG_LEVEL: z.string(),
                    NX_PORT: z.number().transform(toStr),
                    NX_SENTRY_DSN: z.string(),
                })
                .strict(),
        })
        .strict(),
})

const maybeAppWorkersStackContext = z
    .object({
        DesiredTaskCount: z.number(),
        ComputeCapacity: fargateComputeSchema,
        Container: z
            .object({
                Env: z
                    .object({
                        NX_PORT: z.number().transform(toStr),
                        NX_SENTRY_DSN: z.string(),
                    })
                    .strict(),
            })
            .strict(),
    })
    .strict()

const maybeAppStackContexts = z
    .object({
        Shared: maybeAppSharedStackContext,
        Server: maybeAppServerStackContext,
        Workers: maybeAppWorkersStackContext,
    })
    .strict()

const stagingEnvSchema = z
    .object({
        ENV_NAME: z.literal('staging'),
        AWS_ACCOUNT: z.literal('REPLACE_THIS'),
        DEFAULT_AWS_REGION: z.literal('us-west-2'),
        sharedEnv: maybeAppSharedEnv,
        stackContexts: maybeAppStackContexts,
    })
    .strict()

const prodEnvSchema = z
    .object({
        ENV_NAME: z.literal('production'),
        AWS_ACCOUNT: z.literal('541001830411'),
        DEFAULT_AWS_REGION: z.literal('us-west-2'),
        sharedEnv: maybeAppSharedEnv,
        stackContexts: maybeAppStackContexts,
    })
    .strict()

const toolsStackContexts = z
    .object({
        Tools: z.object({
            VPC: z
                .object({
                    IPAllowList: z.string().array().max(20),
                })
                .strict(),
            GithubRunner: z
                .object({
                    SSMKeyArn: z.string(),
                    GithubTokenArn: z.string(),
                })
                .strict(),
        }),
    })
    .strict()

const toolsSharedEnv = z.object({}).strict()

const toolsEnvSchema = z
    .object({
        ENV_NAME: z.literal('tools'),
        AWS_ACCOUNT: z.literal('REPLACE_THIS'),
        DEFAULT_AWS_REGION: z.literal('us-west-2'),
        sharedEnv: toolsSharedEnv,
        stackContexts: toolsStackContexts,
    })
    .strict()

// Determines what account the configuration is deployed to
const envSchema = z
    .object({
        tools: toolsEnvSchema,
        staging: stagingEnvSchema,
        production: prodEnvSchema,
    })
    .strict()

export const getContext = (app: App) => {
    const envKeySchema = z.enum(['tools', 'staging', 'production'])
    const envKey = envKeySchema.parse(process.env.CDK_ENV)

    const envRaw = app.node.tryGetContext('environments')
    if (!envRaw) throw new Error(`cdk.json is in an invalid config state`)

    const env = envSchema.parse(envRaw)

    console.log(`Environment: ${envKey}`)
    console.log(JSON.stringify(env[envKey], null, 2))

    return env[envKey]
}

type MaybeAppContext<TContext> = { sharedEnv: z.infer<typeof maybeAppSharedEnv> } & {
    DEFAULT_AWS_REGION: string
} & TContext

export type SharedStackContext = MaybeAppContext<z.infer<typeof maybeAppStackContexts>['Shared']>
export type ServerStackContext = MaybeAppContext<z.infer<typeof maybeAppStackContexts>['Server']>
export type WorkersStackContext = MaybeAppContext<z.infer<typeof maybeAppStackContexts>['Workers']>

type ToolsContext<TContext> = { sharedEnv: z.infer<typeof toolsSharedEnv> } & {
    DEFAULT_AWS_REGION: string
} & TContext

export type ToolsStackContext = ToolsContext<z.infer<typeof toolsStackContexts>['Tools']>
