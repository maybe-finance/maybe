import {
    BlockDeviceVolume,
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
import {
    ManagedPolicy,
    PolicyDocument,
    PolicyStatement,
    Role,
    ServicePrincipal,
} from 'aws-cdk-lib/aws-iam'
import { Construct } from 'constructs'
import { ToolsStackContext } from '../../utils/get-context'
import * as path from 'path'
import { readFileSync } from 'fs'

export interface GithubActionsRunnerProps {
    vpc: IVpc
}

/**
 * Registers an on-demand EC2 instance for running GH Actions workflows
 */
export class GithubActionsRunner extends Construct {
    constructor(
        scope: Construct,
        id: string,
        props: GithubActionsRunnerProps,
        ctx: ToolsStackContext
    ) {
        super(scope, id)

        const runnerSG = new SecurityGroup(this, 'RunnerSecurityGroup', {
            vpc: props.vpc,
        })

        ctx.VPC.IPAllowList.forEach((ip, index) => {
            runnerSG.addIngressRule(Peer.ipv4(`${ip}/32`), Port.tcp(22))
        })

        // Details retrieved from console, see command below:
        // aws ec2 describe-images --region us-west-2 --image-ids ami-0cfa91bdbc3be780c
        const ami = {
            id: 'ami-0cfa91bdbc3be780c',
            deviceName: '/dev/sda1',
        }

        const runner = new Instance(this, 'GithubActionsRunner', {
            vpc: props.vpc,
            vpcSubnets: { subnetType: SubnetType.PUBLIC },
            machineImage: MachineImage.genericLinux({
                [ctx.DEFAULT_AWS_REGION]: ami.id,
            }),
            instanceType: InstanceType.of(InstanceClass.T3A, InstanceSize.MEDIUM),
            securityGroup: runnerSG,
            // This role allows for Session Manager connections - https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html
            role: new Role(this, 'SessionManagerRole', {
                assumedBy: new ServicePrincipal('ec2.amazonaws.com'),
                description: 'Allows Session Manager to connect to EC2 instance',
                managedPolicies: [
                    ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'),
                ],
                inlinePolicies: {
                    // Allows EC2 instance to grab the Github PAT and make a call to get a "create runner" registration token from Github API
                    ReadGithubKey: new PolicyDocument({
                        statements: [
                            new PolicyStatement({
                                actions: ['kms:Decrypt'],
                                resources: [ctx.GithubRunner.SSMKeyArn],
                            }),
                            new PolicyStatement({
                                actions: ['ssm:GetParameters'],
                                resources: [ctx.GithubRunner.GithubTokenArn],
                            }),
                        ],
                    }),
                },
            }),
            blockDevices: [
                {
                    deviceName: ami.deviceName,
                    volume: BlockDeviceVolume.ebs(100),
                },
            ],
            userDataCausesReplacement: true,
        })

        runner.addUserData(
            readFileSync(path.join(__dirname, './configure-github-runner.sh'), 'utf8')
        )

        // Associate the keypair for SSH connections - https://stackoverflow.com/a/60713522/7437737
        runner.instance.addPropertyOverride('KeyName', 'gh-actions-runner-key') // key was manually created in Console, available in 1Password
    }
}
