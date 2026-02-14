$StackName = "github-oidc-deploy"
$TemplateFile = "iac/github_oidc.yaml"
$Profile = "dev"

Write-Host "Deploying OIDC Stack to Dev account..." -ForegroundColor Cyan

aws cloudformation deploy `
    --stack-name $StackName `
    --template-file $TemplateFile `
    --capabilities CAPABILITY_NAMED_IAM `
    --profile $Profile `
    --no-cli-pager

if ($LASTEXITCODE -eq 0) {
    $roleArn = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --query "Stacks[0].Outputs[?OutputKey=='RoleArn'].OutputValue" `
        --output text `
        --profile $Profile `
        --no-cli-pager
    
    Write-Host "`nStack deployed successfully!" -ForegroundColor Green
    Write-Host "Set 'AWS_ROLE_TO_ASSUME_DEV' in GitHub Secrets to:" -ForegroundColor Yellow
    Write-Host $roleArn -ForegroundColor Cyan
} else {
    Write-Host "Deployment failed!" -ForegroundColor Red
}
