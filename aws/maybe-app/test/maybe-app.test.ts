import * as cdk from 'aws-cdk-lib'
import { Template } from 'aws-cdk-lib/assertions'
import { SharedStack } from '../lib/stacks/shared-stack'
import { ServerStack } from '../lib/stacks/server-stack'
import { WorkersStack } from '../lib/stacks/workers-stack'
import { getContext } from '../lib/utils/get-context'

// Workaround - by default, context is not automatically passed to tests
// https://github.com/aws/aws-cdk/issues/5149#issuecomment-1084788745
import cdkJsonRaw from '../cdk.json'

// ======================================================================
// ===================== STAGING TESTS ==================================
// ======================================================================

test('Shared staging stack created', () => {
    process.env['CDK_ENV'] = 'staging'

    const app = new cdk.App({ context: cdkJsonRaw.context })

    const { DEFAULT_AWS_REGION, sharedEnv, stackContexts } = getContext(app)

    const sharedStack = new SharedStack(
        app,
        'SharedStagingStack',
        {},
        { DEFAULT_AWS_REGION, sharedEnv, ...(stackContexts as any).Shared }
    )

    const template = Template.fromStack(sharedStack)

    // VPC created correctly
    template.resourceCountIs('AWS::EC2::VPC', 1)
    template.resourceCountIs('AWS::EC2::Subnet', 4)
    template.resourceCountIs('AWS::EC2::NatGateway', 1)
    template.resourceCountIs('AWS::EC2::RouteTable', 4)
    template.resourceCountIs('AWS::EC2::EIP', 1)
    template.resourceCountIs('AWS::EC2::InternetGateway', 1)

    // Redis cluster created
    template.resourceCountIs('AWS::ElastiCache::CacheCluster', 1)

    // ECS cluster created
    template.resourceCountIs('AWS::ECS::Cluster', 1)
})

test('Server staging stack created', () => {
    process.env['CDK_ENV'] = 'staging'

    const app = new cdk.App({ context: cdkJsonRaw.context })

    const { DEFAULT_AWS_REGION, sharedEnv, stackContexts } = getContext(app)

    const sharedStack = new SharedStack(
        app,
        'SharedStagingStack',
        {},
        { DEFAULT_AWS_REGION, sharedEnv, ...(stackContexts as any).Shared }
    )

    const serverStack = new ServerStack(
        app,
        'ServerStagingStack',
        {
            sharedStack,
        },
        { DEFAULT_AWS_REGION, sharedEnv, ...(stackContexts as any).Server }
    )

    const template = Template.fromStack(serverStack)

    template.resourceCountIs('AWS::ElasticLoadBalancingV2::LoadBalancer', 1)
    template.resourceCountIs('AWS::ElasticLoadBalancingV2::Listener', 2)
    template.resourceCountIs('AWS::ElasticLoadBalancingV2::TargetGroup', 1)
    template.resourceCountIs('AWS::ECS::TaskDefinition', 1)
    template.resourceCountIs('AWS::ECS::Service', 1)
})

test('Workers staging stack created', () => {
    process.env['CDK_ENV'] = 'staging'

    const app = new cdk.App({ context: cdkJsonRaw.context })

    const { DEFAULT_AWS_REGION, sharedEnv, stackContexts } = getContext(app)

    const sharedStack = new SharedStack(
        app,
        'SharedStagingStack',
        {},
        { DEFAULT_AWS_REGION, sharedEnv, ...(stackContexts as any).Shared }
    )

    const workersStack = new WorkersStack(
        app,
        'WorkersStagingStack',
        {
            sharedStack,
        },
        { DEFAULT_AWS_REGION, sharedEnv, ...(stackContexts as any).Workers }
    )

    const template = Template.fromStack(workersStack)

    template.resourceCountIs('AWS::ECS::TaskDefinition', 1)
    template.resourceCountIs('AWS::ECS::Service', 1)
})

// ======================================================================
// ================== PRODUCTION TESTS ==================================
// ======================================================================

test('Shared production stack created', () => {
    process.env['CDK_ENV'] = 'production'

    const app = new cdk.App({ context: cdkJsonRaw.context })

    const { DEFAULT_AWS_REGION, sharedEnv, stackContexts } = getContext(app)

    const sharedStack = new SharedStack(
        app,
        'SharedStack',
        {},
        { DEFAULT_AWS_REGION, sharedEnv, ...(stackContexts as any).Shared }
    )

    const template = Template.fromStack(sharedStack)

    // VPC created correctly
    template.resourceCountIs('AWS::EC2::VPC', 1)
    template.resourceCountIs('AWS::EC2::Subnet', 4)
    template.resourceCountIs('AWS::EC2::NatGateway', 2)
    template.resourceCountIs('AWS::EC2::RouteTable', 4)
    template.resourceCountIs('AWS::EC2::EIP', 2)
    template.resourceCountIs('AWS::EC2::InternetGateway', 1)

    // Redis cluster created
    template.resourceCountIs('AWS::ElastiCache::CacheCluster', 1)

    // ECS cluster created
    template.resourceCountIs('AWS::ECS::Cluster', 1)
})

test('Server production stack created', () => {
    process.env['CDK_ENV'] = 'production'

    const app = new cdk.App({ context: cdkJsonRaw.context })

    const { DEFAULT_AWS_REGION, sharedEnv, stackContexts } = getContext(app)

    const sharedStack = new SharedStack(
        app,
        'SharedProductionStack',
        {},
        { DEFAULT_AWS_REGION, sharedEnv, ...(stackContexts as any).Shared }
    )

    const serverStack = new ServerStack(
        app,
        'ServerProductionStack',
        {
            sharedStack,
        },
        { DEFAULT_AWS_REGION, sharedEnv, ...(stackContexts as any).Server }
    )

    const template = Template.fromStack(serverStack)

    template.resourceCountIs('AWS::ElasticLoadBalancingV2::LoadBalancer', 1)
    template.resourceCountIs('AWS::ElasticLoadBalancingV2::Listener', 2)
    template.resourceCountIs('AWS::ElasticLoadBalancingV2::TargetGroup', 1)
    template.resourceCountIs('AWS::ECS::TaskDefinition', 1)
    template.resourceCountIs('AWS::ECS::Service', 1)
})

test('Workers production stack created', () => {
    process.env['CDK_ENV'] = 'production'

    const app = new cdk.App({ context: cdkJsonRaw.context })

    const { DEFAULT_AWS_REGION, sharedEnv, stackContexts } = getContext(app)

    const sharedStack = new SharedStack(
        app,
        'SharedProductionStack',
        {},
        { DEFAULT_AWS_REGION, sharedEnv, ...(stackContexts as any).Shared }
    )

    const workersStack = new WorkersStack(
        app,
        'WorkersProductionStack',
        {
            sharedStack,
        },
        { DEFAULT_AWS_REGION, sharedEnv, ...(stackContexts as any).Workers }
    )

    const template = Template.fromStack(workersStack)

    template.resourceCountIs('AWS::ECS::TaskDefinition', 1)
    template.resourceCountIs('AWS::ECS::Service', 1)
})
