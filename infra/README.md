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

Copy the two outputs into GitHub, under **Settings → Secrets and variables →
Actions → Variables** (repository variables, not secrets: they are identifiers):

| Variable | Output |
|---|---|
| `AWS_DEPLOY_ROLE_ARN` | `DeployRoleArn` |
| `ECR_REPOSITORY_URI` | `ImageRepositoryUri` |

## Tearing everything down

Delete the app stack first (it uses the bootstrap stack's runtime role), then
the bootstrap stack. Deleting the bootstrap stack also deletes the stored images.

```bash
aws cloudformation delete-stack --region eu-north-1 --stack-name synreplace-app
aws cloudformation wait stack-delete-complete --region eu-north-1 --stack-name synreplace-app
aws cloudformation delete-stack --region eu-north-1 --stack-name synreplace-bootstrap
```
