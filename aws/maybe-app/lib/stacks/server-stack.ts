import { Duration, Stack, StackProps, Tags } from 'aws-cdk-lib'

import { NetworkMode, Platform } from 'aws-cdk-lib/aws-ecr-assets'
import {
    ContainerImage,
    FargateService,
    FargateTaskDefinition,
    LogDriver,
    PropagatedTagSource,
    Secret as ECSSecret,
} from 'aws-cdk-lib/aws-ecs'
import {
    ApplicationLoadBalancer,
    ApplicationProtocol,
    ApplicationProtocolVersion,
    IApplicationLoadBalancer,
    ListenerAction,
    SslPolicy,
} from 'aws-cdk-lib/aws-elasticloadbalancingv2'
import { Certificate } from 'aws-cdk-lib/aws-certificatemanager'
import { StringParameter } from 'aws-cdk-lib/aws-ssm'
import { Construct } from 'constructs'
import { ServerStackContext } from '../utils/get-context'
import {
    AllowedMethods,
    CachePolicy,
    Distribution,
    OriginProtocolPolicy,
    OriginRequestPolicy,
    OriginSslPolicy,
    PriceClass,
    ViewerProtocolPolicy,
} from 'aws-cdk-lib/aws-cloudfront'
import { LoadBalancerV2Origin } from 'aws-cdk-lib/aws-cloudfront-origins'
import { Secret } from 'aws-cdk-lib/aws-secretsmanager'
import { SharedStack } from './shared-stack'
import { Effect, PolicyStatement } from 'aws-cdk-lib/aws-iam'

interface ServerStackProps extends StackProps {
    sharedStack: SharedStack
}

export class ServerStack extends Stack {
    public readonly loadBalancer: IApplicationLoadBalancer

    constructor(scope: Construct, id: string, props: ServerStackProps, ctx: ServerStackContext) {
        super(scope, id, props)

        const {
            redisUrl,
            userAccessKeyId,
            userAccessSecretArn,
            publicBucketName,
            privateBucketName,
            vpc,
            cluster,
            signerPubKeyId,
            signerSecretId,
        } = props.sharedStack

        const taskDefinition = new FargateTaskDefinition(this, 'ServerTaskDefinition', {
            memoryLimitMiB: +ctx.ComputeCapacity.memory,
            cpu: ctx.ComputeCapacity.cpu,
        })

        // CDK does not add these permissions by default - https://github.com/aws/aws-cdk/issues/17156
        // https://docs.aws.amazon.com/AmazonECS/latest/userguide/specifying-sensitive-data-secrets.html#secrets-iam
        taskDefinition.addToExecutionRolePolicy(
            new PolicyStatement({
                effect: Effect.ALLOW,
                actions: ['secretsmanager:GetSecretValue'],
                resources: [userAccessSecretArn],
            })
        )

        taskDefinition.addContainer('ServerContainer', {
            logging: LogDriver.awsLogs({ streamPrefix: 'server-container' }),
            image: ContainerImage.fromAsset('../../', {
                file: 'apps/server/Dockerfile',
                networkMode: NetworkMode.HOST,
                target: 'prod',
                platform: Platform.LINUX_AMD64, // explicitly define so can build on Macbook M1 (https://stackoverflow.com/a/71102144)
            }),
            environment: {
                AWS_ACCESS_KEY_ID: userAccessKeyId,
                NX_REDIS_URL: redisUrl,
                NX_CDN_PUBLIC_BUCKET: publicBucketName,
                NX_CDN_PRIVATE_BUCKET: privateBucketName,
                NX_CDN_SIGNER_SECRET_ID: signerSecretId,
                NX_CDN_SIGNER_PUBKEY_ID: signerPubKeyId,
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
            stopTimeout: Duration.seconds(10), // waits 10 seconds after SIGTERM to fire SIGKILL
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
                NX_SESSION_SECRET: ECSSecret.fromSsmParameter(
                    StringParameter.fromSecureStringParameterAttributes(
                        this,
                        'SessionSecretParam',
                        {
                            parameterName: '/apps/maybe-app/NX_SESSION_SECRET',
                        }
                    )
                ),
                NX_AUTH0_CLIENT_SECRET: ECSSecret.fromSsmParameter(
                    StringParameter.fromSecureStringParameterAttributes(
                        this,
                        'Auth0ClientSecretParam',
                        {
                            parameterName: '/apps/maybe-app/NX_AUTH0_CLIENT_SECRET',
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
                NX_STRIPE_SECRET_KEY: ECSSecret.fromSsmParameter(
                    StringParameter.fromSecureStringParameterAttributes(
                        this,
                        'StripeSecretKeyParam',
                        {
                            parameterName: '/providers/NX_STRIPE_SECRET_KEY',
                        }
                    )
                ),
                NX_STRIPE_WEBHOOK_SECRET: ECSSecret.fromSsmParameter(
                    StringParameter.fromSecureStringParameterAttributes(
                        this,
                        'StripeWebhookSecretParam',
                        {
                            parameterName: '/providers/NX_STRIPE_WEBHOOK_SECRET',
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
                // references the User access key created in SharedStack
                AWS_SECRET_ACCESS_KEY: ECSSecret.fromSecretsManager(
                    Secret.fromSecretPartialArn(this, 'AwsSdkUserSecret', userAccessSecretArn)
                ),
            },
        })

        const server = new FargateService(this, 'ServerService', {
            cluster, // reference to SharedStack
            taskDefinition,
            enableECSManagedTags: true,
            propagateTags: PropagatedTagSource.SERVICE,
            desiredCount: ctx.DesiredTaskCount,
            circuitBreaker: {
                rollback: true,
            },
        })

        this.loadBalancer = new ApplicationLoadBalancer(this, 'ServerLoadBalancer', {
            vpc, // reference to SharedStack
            internetFacing: true,
        })

        const httpsListener = this.loadBalancer.addListener('PublicListener', {
            protocol: ApplicationProtocol.HTTPS,
            port: 443,
            open: true,
            sslPolicy: SslPolicy.RECOMMENDED,
        })

        httpsListener.addCertificates('ServerLBCertificates', [
            Certificate.fromCertificateArn(this, 'ServerCertificate', ctx.CertificateArn),
        ])

        // Point the load balancer at the ECS task
        httpsListener.addTargets('ECS', {
            protocol: ApplicationProtocol.HTTP,
            protocolVersion: ApplicationProtocolVersion.HTTP1,
            targets: [server],
            deregistrationDelay: Duration.seconds(10),
            healthCheck: {
                path: '/health',
                healthyThresholdCount: 2,
                timeout: Duration.seconds(3),
                interval: Duration.seconds(5),
            },
        })

        // Redirect all HTTP traffic to HTTPs
        this.loadBalancer.addListener('RedirectToHTTPSListener', {
            protocol: ApplicationProtocol.HTTP,
            port: 80,
            open: true,
            defaultAction: ListenerAction.redirect({
                port: '443',
                protocol: ApplicationProtocol.HTTPS,
                permanent: true,
            }),
        })

        // WAF => Cloudfront => ALB
        new Distribution(this, 'ServerCloudfrontDistribution', {
            comment: 'ALB for ECS Fargate server',
            defaultBehavior: {
                origin: new LoadBalancerV2Origin(this.loadBalancer, {
                    protocolPolicy: OriginProtocolPolicy.HTTPS_ONLY,
                    originSslProtocols: [OriginSslPolicy.TLS_V1_1],
                }),
                allowedMethods: AllowedMethods.ALLOW_ALL,
                cachePolicy: CachePolicy.CACHING_DISABLED,
                originRequestPolicy: OriginRequestPolicy.ALL_VIEWER,
                viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
            },
            priceClass: PriceClass.PRICE_CLASS_100,
            webAclId: ctx.WAFArn,
            certificate: Certificate.fromCertificateArn(
                this,
                'CloudfrontCertificate',
                ctx.Cloudfront.CertificateArn
            ),
            domainNames: ctx.Cloudfront.CNAMES,
        })

        // Put a tag on this service so we can track it easier in Cost Explorer
        Tags.of(server).add('ecs-service-name', 'server')
    }
}
