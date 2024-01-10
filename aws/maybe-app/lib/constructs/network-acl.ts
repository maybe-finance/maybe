import {
    AclCidr,
    AclTraffic,
    Action,
    IVpc,
    NetworkAcl,
    SubnetType,
    TrafficDirection,
} from 'aws-cdk-lib/aws-ec2'
import { Construct } from 'constructs'

export interface NetworkACLConfigProps {
    vpc: IVpc
    authorizedIPs?: string[]
}

/**
 * Creates the "best practice" network ACL config for a public/private subnet VPC (some rules are more lenient than the docs suggest)
 *
 * @see https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario2.html#nacl-rules-scenario-2
 */
export class NetworkACLConfig extends Construct {
    public readonly redisUrl: string

    constructor(scope: Construct, id: string, props: NetworkACLConfigProps) {
        super(scope, id)

        const publicNetworkACL = new NetworkAcl(this, 'PublicNetworkACL', {
            vpc: props.vpc,
            subnetSelection: { subnetType: SubnetType.PUBLIC },
        })

        // --------------------------------
        // Inbound Public Entries
        // --------------------------------
        publicNetworkACL.addEntry('InboundHTTPPublic', {
            cidr: AclCidr.anyIpv4(),
            ruleNumber: 101,
            traffic: AclTraffic.tcpPort(80),
            direction: TrafficDirection.INGRESS,
            ruleAction: Action.ALLOW,
        })

        publicNetworkACL.addEntry('InboundHTTPSPublic', {
            cidr: AclCidr.anyIpv4(),
            ruleNumber: 110,
            traffic: AclTraffic.tcpPort(443),
            direction: TrafficDirection.INGRESS,
            ruleAction: Action.ALLOW,
        })

        // Individual IP address inbound access (20 reserved slots)
        // http://checkip.amazonaws.com/
        if (props.authorizedIPs?.length) {
            props.authorizedIPs.forEach((ip, index) => {
                publicNetworkACL.addEntry(`IPAllowPublic${index}`, {
                    cidr: AclCidr.ipv4(`${ip}/32`),
                    ruleNumber: 111 + index,
                    traffic: AclTraffic.tcpPort(22),
                    direction: TrafficDirection.INGRESS,
                    ruleAction: Action.ALLOW,
                })
            })
        }

        publicNetworkACL.addEntry('EphemeralInboundPublic', {
            cidr: AclCidr.anyIpv4(),
            ruleNumber: 140,
            traffic: AclTraffic.tcpPortRange(1024, 65535),
            direction: TrafficDirection.INGRESS,
            ruleAction: Action.ALLOW,
        })

        // --------------------------------
        // Outbound Public Entries
        // --------------------------------

        publicNetworkACL.addEntry('AllowAllOutbound', {
            cidr: AclCidr.anyIpv4(),
            ruleNumber: 100,
            traffic: AclTraffic.allTraffic(),
            direction: TrafficDirection.EGRESS,
            ruleAction: Action.ALLOW,
        })

        if (props.vpc.privateSubnets.length) {
            const privateNetworkACL = new NetworkAcl(this, 'PrivateNetworkACL', {
                vpc: props.vpc,
                subnetSelection: { subnetType: SubnetType.PRIVATE_WITH_EGRESS },
            })

            // --------------------------------
            // Inbound Private Entries
            // --------------------------------

            // Allow all inbound traffic from public subnets
            props.vpc
                .selectSubnets({ subnetType: SubnetType.PUBLIC })
                .subnets.forEach((sn, index) => {
                    privateNetworkACL.addEntry(`InboundPrivate${index}`, {
                        cidr: AclCidr.ipv4(sn.ipv4CidrBlock),
                        ruleNumber: 101 + index,
                        traffic: AclTraffic.allTraffic(),
                        direction: TrafficDirection.INGRESS,
                        ruleAction: Action.ALLOW,
                    })
                })

            privateNetworkACL.addEntry('InboundEphemeralPrivate', {
                cidr: AclCidr.anyIpv4(),
                ruleNumber: 110,
                traffic: AclTraffic.tcpPortRange(1024, 65535),
                direction: TrafficDirection.INGRESS,
                ruleAction: Action.ALLOW,
            })

            // --------------------------------
            // Outbound Private Entries
            // --------------------------------

            privateNetworkACL.addEntry('AllowAllEgressPrivate', {
                cidr: AclCidr.anyIpv4(),
                ruleNumber: 100,
                traffic: AclTraffic.allTraffic(),
                direction: TrafficDirection.EGRESS,
                ruleAction: Action.ALLOW,
            })
        }
    }
}
