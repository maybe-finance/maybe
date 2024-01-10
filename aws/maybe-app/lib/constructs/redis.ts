import { IVpc, Peer, Port, SecurityGroup, SubnetType } from 'aws-cdk-lib/aws-ec2'
import { CfnCacheCluster, CfnCacheClusterProps, CfnSubnetGroup } from 'aws-cdk-lib/aws-elasticache'
import { LogGroup, RetentionDays } from 'aws-cdk-lib/aws-logs'
import { Construct } from 'constructs'

export interface RedisProps {
    vpc: IVpc
    redisConfig: Pick<CfnCacheClusterProps, 'numCacheNodes' | 'cacheNodeType'>
}

export class Redis extends Construct {
    public readonly redisUrl: string

    constructor(scope: Construct, id: string, props: RedisProps) {
        super(scope, id)

        const redisSecurityGroup = new SecurityGroup(this, 'RedisSecurityGroup', {
            vpc: props.vpc,
            description: 'Redis instance security group',
            allowAllOutbound: true,
        })

        const privateSubnets = props.vpc.selectSubnets({
            subnetType: SubnetType.PRIVATE_WITH_EGRESS,
        })

        const redisSubnetGroup = new CfnSubnetGroup(this, 'RedisSubnetGroup', {
            description: 'Subnet group for Redis cluster',
            subnetIds: privateSubnets.subnetIds,
            cacheSubnetGroupName: 'redis-subnet',
        })

        const REDIS_PORT = 6379

        const { logGroupName } = new LogGroup(this, 'RedisLogGroup', {
            retention: RetentionDays.TWO_WEEKS,
        })

        const redisCluster = new CfnCacheCluster(this, 'RedisCluster', {
            engine: 'redis',
            cacheNodeType: props.redisConfig.cacheNodeType,
            numCacheNodes: props.redisConfig.numCacheNodes,
            autoMinorVersionUpgrade: true,
            port: REDIS_PORT,
            vpcSecurityGroupIds: [redisSecurityGroup.securityGroupId],
            cacheSubnetGroupName: 'redis-subnet',
            logDeliveryConfigurations: [
                {
                    destinationDetails: { cloudWatchLogsDetails: { logGroup: logGroupName } },
                    destinationType: 'cloudwatch-logs',
                    logFormat: 'json',
                    logType: 'slow-log',
                },
                {
                    destinationDetails: {
                        cloudWatchLogsDetails: { logGroup: logGroupName },
                    },
                    destinationType: 'cloudwatch-logs',
                    logFormat: 'json',
                    logType: 'engine-log',
                },
            ],
        })

        // Require the subnet group to be created before the cluster
        redisCluster.node.addDependency(redisSubnetGroup)

        // Open incoming traffic to the Redis port (e.g. 6379)
        redisSecurityGroup.addIngressRule(Peer.anyIpv4(), Port.tcp(REDIS_PORT))

        this.redisUrl = `redis://${redisCluster.attrRedisEndpointAddress}:${redisCluster.attrRedisEndpointPort}`
    }
}
