## Local deployment

**PROD should not be deployed locally**

To test a local deployment:

1. Set `~/.aws/credentials` file to have a profile called `[maybe_tools]` which should have credentials of IAM user in the tools account (which can cross-deploy to staging/prod accounts). Additional security creds can be generated in AWS dashboard.

```
[maybe_tools]
aws_access_key_id=
aws_secret_access_key=
region=us-east-1
output=json
```

2. Run `yarn cdk:ls` to verify everything is working correctly

3. Run `yarn cdk deploy [SomeStack] --profile=maybe_tools` to deploy a certain stack in the **staging** environment. Production should not be deployed locally ever.
