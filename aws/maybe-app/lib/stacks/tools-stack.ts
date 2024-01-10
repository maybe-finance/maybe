import { Stack, StackProps } from 'aws-cdk-lib'
import { SubnetType, Vpc } from 'aws-cdk-lib/aws-ec2'
import { Construct } from 'constructs'
import { GithubActionsRunner } from '../constructs/github-actions-runner/github-actions-runner'
import { NetworkACLConfig } from '../constructs/network-acl'
import { ToolsStackContext } from '../utils/get-context'

interface ToolsStackProps extends StackProps {}

/**
 * Resources deployed to the Deployments account for CI/CD purposes
 */
export class ToolsStack extends Stack {
    constructor(scope: Construct, id: string, props: ToolsStackProps, ctx: ToolsStackContext) {
        super(scope, id, props)

        const vpc = new Vpc(this, 'ToolsVPC', {
            maxAzs: 1,
            natGateways: 0,
            subnetConfiguration: [{ subnetType: SubnetType.PUBLIC, name: 'public' }],
        })

        new NetworkACLConfig(this, 'ToolsNetworkACL', {
            vpc,
            authorizedIPs: ctx.VPC.IPAllowList,
        })

        new GithubActionsRunner(this, 'GithubActionsRunnerInstance', { vpc }, ctx)
    }
}
