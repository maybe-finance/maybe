#!/usr/bin/env node
import 'source-map-support/register'
import * as cdk from 'aws-cdk-lib'
import { getContext } from '../lib/utils/get-context'
import { SharedStack } from '../lib/stacks/shared-stack'
import { ServerStack } from '../lib/stacks/server-stack'
import { WorkersStack } from '../lib/stacks/workers-stack'
import { StackProps } from 'aws-cdk-lib'
import { ToolsStack } from '../lib/stacks/tools-stack'

const app = new cdk.App()

const ctx = getContext(app)

const { AWS_ACCOUNT, DEFAULT_AWS_REGION, ENV_NAME, sharedEnv, stackContexts } = ctx

const commonStackProps: StackProps = {
    env: {
        region: DEFAULT_AWS_REGION,
        account: AWS_ACCOUNT,
    },
    tags: {
        environment: ENV_NAME,
        'deploy-type': 'cdk',
    },
}

if (ENV_NAME === 'tools') {
    new ToolsStack(
        app,
        'ToolsStack',
        {
            ...commonStackProps,
            stackName: `ci-cd-deployments-tools-stack`,
            description: 'Resources used for CI/CD, such as self-hosted runners and pipelines',
        },
        {
            DEFAULT_AWS_REGION,
            sharedEnv,
            ...stackContexts.Tools,
        }
    )
}

if (ENV_NAME === 'staging' || ENV_NAME === 'production') {
    const sharedStack = new SharedStack(
        app,
        'SharedStack',
        {
            ...commonStackProps,
            stackName: `maybe-app-${ENV_NAME}-shared-stack`,
            description:
                'Common infrastructure used by all services including VPC, Redis, and ECS Cluster',
        },
        {
            DEFAULT_AWS_REGION,
            sharedEnv,
            ...stackContexts.Shared,
        }
    )

    new ServerStack(
        app,
        'ServerStack',
        {
            ...commonStackProps,
            stackName: `maybe-app-${ENV_NAME}-server-stack`,
            description: 'ECS Fargate RESTful API with ALB, Cloudfront, and WAF',
            sharedStack,
        },
        {
            DEFAULT_AWS_REGION,
            sharedEnv,
            ...stackContexts.Server,
        }
    )

    new WorkersStack(
        app,
        'WorkersStack',
        {
            ...commonStackProps,
            stackName: `maybe-app-${ENV_NAME}-workers-stack`,
            description: 'Bull.js workers on ECS Fargate',
            sharedStack,
        },
        {
            DEFAULT_AWS_REGION,
            sharedEnv,
            ...stackContexts.Workers,
        }
    )
}
