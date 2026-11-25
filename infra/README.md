# Infrastructure

AWS setup for running the web app (`web/`) on Lambda, region `eu-north-1`.

| File | Deployed by | Creates |
|---|---|---|
| `bootstrap.yaml` | You, once, from AWS CloudShell | ECR repository, GitHub OIDC login, deploy role, the Lambda's runtime role and log group |
| `app.yaml` | GitHub Actions, on every push to `main` | The Lambda function and its public Function URL |

## One-time bootstrap (AWS CloudShell)

```bash
git clone https://github.com/BartaLazar/LLM-watermark-remover.git
cd LLM-watermark-remover

aws cloudformation deploy \
  --region eu-north-1 \
  --stack-name synreplace-bootstrap \
  --template-file infra/bootstrap.yaml \
  --capabilities CAPABILITY_IAM

aws cloudformation describe-stacks \
  --region eu-north-1 \
  --stack-name synreplace-bootstrap \
  --query "Stacks[0].Outputs" --output table
```

**Updating the stack later:** run the same `deploy` command again. Parameter
defaults only apply when the stack is first created; on updates it keeps each
parameter's previous value. To change one, pass it explicitly, e.g.
`--parameter-overrides GitHubRepo=owner@id/repo@id`.

Copy the two outputs into GitHub, under **Settings → Secrets and variables →
Actions → Secrets → New repository secret**:

| Secret | Output |
|---|---|
| `AWS_DEPLOY_ROLE_ARN` | `DeployRoleArn` |
| `ECR_REPOSITORY_URI` | `ImageRepositoryUri` |

Both contain the AWS account ID. They are stored as secrets, not variables,
because this repository is public and so are its Actions logs: GitHub masks
secrets as `***` in logs, but prints variables in plain text. Never paste the
outputs into a tracked file.

## Tearing everything down

Delete the app stack first (it uses the bootstrap stack's runtime role), then
the bootstrap stack. Deleting the bootstrap stack also deletes the stored images.

```bash
aws cloudformation delete-stack --region eu-north-1 --stack-name synreplace-app
aws cloudformation wait stack-delete-complete --region eu-north-1 --stack-name synreplace-app
aws cloudformation delete-stack --region eu-north-1 --stack-name synreplace-bootstrap
```
