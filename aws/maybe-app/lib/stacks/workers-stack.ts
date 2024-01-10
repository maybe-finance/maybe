import { Duration, Stack, StackProps, Tags } from 'aws-cdk-lib'
import { NetworkMode, Platform } from 'aws-cdk-lib/aws-ecr-assets'
import {
    ContainerImage,
    FargateService,
    FargateTaskDefinition,
    LogDrivers,
    PropagatedTagSource,
    Secret as ECSSecret,
} from 'aws-cdk-lib/aws-ecs'
import { Effect, PolicyStatement } from 'aws-cdk-lib/aws-iam'
import { Secret } from 'aws-cdk-lib/aws-secretsmanager'
import { StringParameter } from 'aws-cdk-lib/aws-ssm'
import { Construct } from 'constructs'
import { WorkersStackContext } from '../utils/get-context'
import { SharedStack } from './shared-stack'

interface WorkersStackProps extends StackProps {
    sharedStack: SharedStack
}

export class WorkersStack extends Stack {
    constructor(scope: Construct, id: string, props: WorkersStackProps, ctx: WorkersStackContext) {
        super(scope, id, props)

        const {
            redisUrl,
            userAccessKeyId,
            userAccessSecretArn,
            publicBucketName,
            privateBucketName,
            cluster,
        } = props.sharedStack

        const workerTask = new FargateTaskDefinition(this, 'WorkerTaskDefinition', {
            memoryLimitMiB: +ctx.ComputeCapacity.memory,
            cpu: ctx.ComputeCapacity.cpu,
        })

        // CDK does not add these permissions by default - https://github.com/aws/aws-cdk/issues/17156
        // https://docs.aws.amazon.com/AmazonECS/latest/userguide/specifying-sensitive-data-secrets.html#secrets-iam
        workerTask.addToExecutionRolePolicy(
            new PolicyStatement({
                effect: Effect.ALLOW,
                actions: ['secretsmanager:GetSecretValue'],
                resources: [userAccessSecretArn],
            })
        )

        workerTask.addContainer('worker-container', {
            logging: LogDrivers.awsLogs({ streamPrefix: 'WorkerLog' }),
            image: ContainerImage.fromAsset('../../', {
                file: 'apps/workers/Dockerfile',
                networkMode: NetworkMode.HOST,
                target: 'prod',
                platform: Platform.LINUX_AMD64, // explicitly define so can build on Macbook M1 (https://stackoverflow.com/a/71102144)
            }),
            environment: {
                AWS_ACCESS_KEY_ID: userAccessKeyId,
                NX_REDIS_URL: redisUrl,
                NX_CDN_PUBLIC_BUCKET: publicBucketName,
                NX_CDN_PRIVATE_BUCKET: privateBucketName,
                ...ctx.sharedEnv,
                ...ctx.Container.Env,
            },
            portMappings: [{ containerPort: +ctx.Container.Env.NX_PORT }],
            entryPoint: ['sh', '-c'],
            command: ['/bin/sh -c "node ./main.js"'],
            healthCheck: {
                command: [
                    'CMD-SHELL',
                    `curl --fail -s http://localhost:${ctx.Container.Env.NX_PORT}/health || exit 1`,
                ],
                interval: Duration.seconds(10),
                retries: 3,
                startPeriod: Duration.seconds(10),
                timeout: Duration.seconds(5),
            },
            stopTimeout: Duration.seconds(10),
            secrets: {
                NX_DATABASE_URL: ECSSecret.fromSsmParameter(
                    StringParameter.fromSecureStringParameterAttributes(this, 'DatabaseUrlParam', {
                        parameterName: '/apps/maybe-app/NX_DATABASE_URL',
                    })
                ),
                NX_DATABASE_SECRET: ECSSecret.fromSsmParameter(
                    StringParameter.fromSecureStringParameterAttributes(
                        this,
                        'DatabaseSecretParam',
                        {
                            parameterName: '/apps/maybe-app/NX_DATABASE_SECRET',
                        }
                    )
                ),
                NX_AUTH0_MGMT_CLIENT_SECRET: ECSSecret.fromSsmParameter(
                    StringParameter.fromSecureStringParameterAttributes(
                        this,
                        'Auth0MgmtClientSecretParam',
                        {
                            parameterName: '/apps/maybe-app/NX_AUTH0_MGMT_CLIENT_SECRET',
                        }
                    )
                ),
                NX_PLAID_SECRET: ECSSecret.fromSsmParameter(
                    StringParameter.fromSecureStringParameterAttributes(this, 'PlaidSecretParam', {
                        parameterName: '/providers/NX_PLAID_SECRET',
                    })
                ),
                NX_FINICITY_APP_KEY: ECSSecret.fromSsmParameter(
                    StringParameter.fromSecureStringParameterAttributes(
                        this,
                        'FinicityAppKeyParam',
                        {
                            parameterName: '/providers/NX_FINICITY_APP_KEY',
                        }
                    )
                ),
                NX_FINICITY_PARTNER_SECRET: ECSSecret.fromSsmParameter(
                    StringParameter.fromSecureStringParameterAttributes(
                        this,
                        'FinicityPartnerSecretParam',
                        {
                            parameterName: '/providers/NX_FINICITY_PARTNER_SECRET',
                        }
                    )
                ),
                NX_POLYGON_API_KEY: ECSSecret.fromSsmParameter(
                    StringParameter.fromSecureStringParameterAttributes(
                        this,
                        'PolygonApiKeyParam',
                        {
                            parameterName: '/providers/NX_POLYGON_API_KEY',
                        }
                    )
                ),
                NX_POSTMARK_API_TOKEN: ECSSecret.fromSsmParameter(
                    StringParameter.fromSecureStringParameterAttributes(
                        this,
                        'PostmarkApiTokenParam',
                        {
                            parameterName: '/providers/NX_POSTMARK_API_TOKEN',
                        }
                    )
                ),
                NX_STRIPE_SECRET_KEY: ECSSecret.fromSsmParameter(
                    StringParameter.fromSecureStringParameterAttributes(
                        this,
                        'StripeSecretKeyParam',
                        {
                            parameterName: '/providers/NX_STRIPE_SECRET_KEY',
                        }
                    )
                ),
                // references the User access key created in SharedStack
                AWS_SECRET_ACCESS_KEY: ECSSecret.fromSecretsManager(
                    Secret.fromSecretPartialArn(this, 'AwsSdkUserSecret', userAccessSecretArn)
                ),
            },
        })

        const workerService = new FargateService(this, 'WorkerService', {
            cluster, // reference from SharedStack
            taskDefinition: workerTask,

            enableECSManagedTags: true,
            propagateTags: PropagatedTagSource.SERVICE,

            // ECS deployment config
            // https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-ecs.html#deployment-circuit-breaker
            desiredCount: ctx.DesiredTaskCount,
            circuitBreaker: {
                rollback: true,
            },
        })

        // Tag service for easier tracking in cost explorer
        Tags.of(workerService).add('ecs-service-name', 'workers')
    }
}
