import { RemovalPolicy, Stack, StackProps } from 'aws-cdk-lib'
import { Certificate } from 'aws-cdk-lib/aws-certificatemanager'
import { Distribution, KeyGroup, PriceClass, PublicKey } from 'aws-cdk-lib/aws-cloudfront'
import { S3Origin } from 'aws-cdk-lib/aws-cloudfront-origins'
import {
    CfnRoute,
    GatewayVpcEndpointAwsService,
    InterfaceVpcEndpointAwsService,
    IVpc,
    Vpc,
} from 'aws-cdk-lib/aws-ec2'
import { Cluster, ICluster } from 'aws-cdk-lib/aws-ecs'
import { AccessKey, Policy, PolicyStatement, User } from 'aws-cdk-lib/aws-iam'
import { Bucket, CfnBucket, HttpMethods } from 'aws-cdk-lib/aws-s3'
import { Secret } from 'aws-cdk-lib/aws-secretsmanager'
import { Construct } from 'constructs'
import { JumpBox } from '../constructs/jump-box'
import { NetworkACLConfig } from '../constructs/network-acl'
import { Redis } from '../constructs/redis'
import { SharedStackContext } from '../utils/get-context'
import { StringParameter } from 'aws-cdk-lib/aws-ssm'

interface SharedStackProps extends StackProps {}

/**
 * Shared resources that workloads are deployed to
 *
 * @see - https://docs.aws.amazon.com/cdk/api/v2/docs/aws-cdk-lib.aws_ec2.Vpc.html
 */
export class SharedStack extends Stack {
    public readonly vpc: IVpc
    public readonly cluster: ICluster
    public readonly redisUrl: string
    public readonly userAccessSecretArn: string
    public readonly userAccessKeyId: string
    public readonly privateBucketName: string
    public readonly publicBucketName: string
    public readonly signerSecretId: string
    public readonly signerPubKeyId: string

    constructor(scope: Construct, id: string, props: SharedStackProps, ctx: SharedStackContext) {
        super(scope, id, props)

        this.vpc = new Vpc(this, 'MaybeAppVPC', {
            maxAzs: 2,
            natGateways: ctx.VPC.NATCount,
        })

        new NetworkACLConfig(this, 'MaybeAppVPCNetworkACLConfig', {
            vpc: this.vpc,
            authorizedIPs: ctx.VPC.IPAllowList,
        })

        // Fargate >= 1.4.0 requires S3 Gateway, ECR, ECR Docker, and Cloudwatch Logs
        // https://docs.aws.amazon.com/AmazonECR/latest/userguide/vpc-endpoints.html#ecr-vpc-endpoint-considerations
        this.vpc.addGatewayEndpoint('S3GatewayEndpoint', {
            service: GatewayVpcEndpointAwsService.S3,
        })

        this.vpc.addInterfaceEndpoint('ECRInterfaceEndpoint', {
            service: InterfaceVpcEndpointAwsService.ECR,
        })

        this.vpc.addInterfaceEndpoint('DockerInterfaceEndpoint', {
            service: InterfaceVpcEndpointAwsService.ECR_DOCKER,
        })

        // Containers write logs directly to Cloudwatch
        this.vpc.addInterfaceEndpoint('CloudwatchLogsInterfaceEndpoint', {
            service: InterfaceVpcEndpointAwsService.CLOUDWATCH_LOGS,
        })

        // Open a communication channel with TimescaleDB
        if (ctx.PeeringCnxId) {
            const addPeeringRoute = (routeTableId: string, index: number, subnetType: string) => {
                new CfnRoute(this, `PeeringRoute-${subnetType}-${index}`, {
                    destinationCidrBlock: ctx.PeeringCnxCidr,
                    routeTableId,
                    vpcPeeringConnectionId: ctx.PeeringCnxId,
                })
            }

            // Allows our private services to connect to DB
            this.vpc.privateSubnets.forEach((subnet, index) =>
                addPeeringRoute(subnet.routeTable.routeTableId, index, 'private')
            )

            // This allows our JumpBox SSH tunnel to work
            this.vpc.publicSubnets.forEach((subnet, index) =>
                addPeeringRoute(subnet.routeTable.routeTableId, index, 'public')
            )
        }

        // The ECS Cluster that all ECS services and tasks are deployed to
        this.cluster = new Cluster(this, 'ECSCluster', { vpc: this.vpc })

        const redis = new Redis(this, 'Redis', {
            vpc: this.vpc,
            redisConfig: {
                numCacheNodes: ctx.Redis.count,
                cacheNodeType: ctx.Redis.size,
            },
        })

        this.redisUrl = redis.redisUrl

        // For connecting to DB through EC2 instance as SSH tunnel
        new JumpBox(this, 'JumpBox', { vpc: this.vpc }, ctx)

        // Where we put public assets like fonts, logos, etc.
        // Everything stored here is publicly available over our CDN
        const publicBucket = new Bucket(this, 'Public', {
            removalPolicy: RemovalPolicy.RETAIN,
        })

        // WORM compliant bucket to store CDN assets such as client agreements, AMA uploads
        const privateBucket = new Bucket(this, 'Assets', {
            versioned: true,
            removalPolicy: RemovalPolicy.RETAIN,
            cors: [
                {
                    allowedHeaders: [
                        'Authorization',
                        'x-amz-date',
                        'x-amz-content-sha256',
                        'content-type',
                    ],
                    allowedMethods: [HttpMethods.GET, HttpMethods.POST],
                    allowedOrigins: ctx.UploadOrigins,
                },
            ],
        })

        const privateBucketRef = privateBucket.node.defaultChild as CfnBucket
        privateBucketRef.addPropertyOverride('ObjectLockEnabled', true)
        privateBucketRef.addPropertyOverride('ObjectLockConfiguration.ObjectLockEnabled', 'Enabled')
        privateBucketRef.addPropertyOverride(
            'ObjectLockConfiguration.Rule.DefaultRetention.Years',
            5
        )
        privateBucketRef.addPropertyOverride(
            'ObjectLockConfiguration.Rule.DefaultRetention.Mode',
            'GOVERNANCE'
        )

        const signerPublicKey = StringParameter.fromStringParameterName(
            this,
            'SignerPKParam',
            '/apps/maybe-app/CLOUDFRONT_SIGNER1_PUB'
        )

        const signerPubKey = new PublicKey(this, 'SignerPub', {
            encodedKey: signerPublicKey.stringValue,
        })

        // server app will grab this ID as a reference
        this.signerPubKeyId = signerPubKey.publicKeyId

        const signerPrivateKey = Secret.fromSecretNameV2(
            this,
            'SignerPriv',
            '/apps/maybe-app/CLOUDFRONT_SIGNER1_PRIV'
        )

        // server app will dynamically grab this (via SDK) by its ID to sign urls
        this.signerSecretId = signerPrivateKey.secretName

        // This group holds public keys that can sign URLs and cookies to serve restricted content from the Distribution
        const keyGroup = new KeyGroup(this, 'KeyGroup', {
            items: [signerPubKey],
        })

        const distribution = new Distribution(this, 'Distribution', {
            comment: 'Maybe App Cloudfront CDN',
            domainNames: ctx.Cloudfront.CNAMES,
            certificate: Certificate.fromCertificateArn(
                this,
                'CdnCert',
                ctx.Cloudfront.CertificateArn
            ),
            defaultBehavior: {
                origin: new S3Origin(publicBucket),
            },
            additionalBehaviors: {
                // All content served here requires signed urls to view
                '/private/*': {
                    origin: new S3Origin(privateBucket),
                    trustedKeyGroups: [keyGroup],
                },
            },
            priceClass: PriceClass.PRICE_CLASS_100,
        })

        /**
         * User that AWS SDK will use within server and workers apps
         *
         * Permissions added as-needed here.
         */
        const user = new User(this, 'SdkUser')
        user.attachInlinePolicy(
            new Policy(this, 'SdkUserPolicy', {
                statements: [
                    new PolicyStatement({
                        actions: ['s3:PutObject', 's3:GetObject', 's3:GetObjectAttributes'],
                        resources: [`${privateBucket.bucketArn}/*`, `${publicBucket.bucketArn}/*`],
                    }),
                    new PolicyStatement({
                        actions: ['secretsmanager:GetSecretValue'],
                        // Can access any key stored under the /apps/maybe-app path
                        resources: [
                            `arn:aws:secretsmanager:${this.region}:${this.account}:secret:/apps/maybe-app/*`,
                        ],
                    }),
                ],
            })
        )

        // Access key secret safely stored in secrets manager (and retrieved in server/workers stacks)
        const accessKey = new AccessKey(this, 'SdkUserAcessKey', { user })
        const accessKeySecret = new Secret(this, 'SdkUserAccessKeySecret', {
            secretStringValue: accessKey.secretAccessKey,
        })

        this.userAccessKeyId = accessKey.accessKeyId
        this.userAccessSecretArn = accessKeySecret.secretArn
        this.privateBucketName = privateBucket.bucketName
        this.publicBucketName = publicBucket.bucketName
    }
}
