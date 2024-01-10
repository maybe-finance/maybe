import {
    Instance,
    InstanceClass,
    InstanceSize,
    InstanceType,
    IVpc,
    MachineImage,
    Peer,
    Port,
    SecurityGroup,
    SubnetType,
} from 'aws-cdk-lib/aws-ec2'
import { ManagedPolicy, Role, ServicePrincipal } from 'aws-cdk-lib/aws-iam'
import { Construct } from 'constructs'
import { SharedStackContext } from '../utils/get-context'

export interface JumpBoxProps {
    vpc: IVpc
}

/**
 * Creates a "Jump Box", or "Bastion" EC2 instance in public subnet for connections to Postgres
 */
export class JumpBox extends Construct {
    public readonly redisUrl: string

    constructor(scope: Construct, id: string, props: JumpBoxProps, ctx: SharedStackContext) {
        super(scope, id)

        const jumpBoxSecurityGroup = new SecurityGroup(this, 'JumpBoxSecurityGroup', {
            vpc: props.vpc,
        })

        // Allow SSH connections to specified IP addresses
        ctx.VPC.IPAllowList.forEach((ip, index) => {
            jumpBoxSecurityGroup.addIngressRule(Peer.ipv4(`${ip}/32`), Port.tcp(22))
        })

        const jumpBox = new Instance(this, 'JumpBox', {
            vpc: props.vpc,
            vpcSubnets: { subnetType: SubnetType.PUBLIC },
            machineImage: MachineImage.genericLinux({
                [ctx.DEFAULT_AWS_REGION]: 'ami-0cfa91bdbc3be780c',
            }),
            instanceType: InstanceType.of(InstanceClass.T2, InstanceSize.MICRO),
            securityGroup: jumpBoxSecurityGroup,
            // This role allows for Session Manager connections - https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html
            role: new Role(this, 'SessionManagerRole', {
                assumedBy: new ServicePrincipal('ec2.amazonaws.com'),
                description: 'Allows Session Manager to connect to EC2 instance',
                managedPolicies: [
                    ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'),
                ],
            }),
        })

        // Associate the keypair for SSH connections - https://stackoverflow.com/a/60713522/7437737
        jumpBox.instance.addPropertyOverride('KeyName', 'jumpbox-key') // key was manually created in Console, available in 1Password
    }
}
