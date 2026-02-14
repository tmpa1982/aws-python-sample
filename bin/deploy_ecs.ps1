$StackName = "ecs-fargate-app"
$TemplateFile = "iac/ecs.yaml"
$Profile = "dev"
$Region = "ap-southeast-1"

Write-Host "Deploying ECS Stack: $StackName..." -ForegroundColor Cyan

aws cloudformation deploy `
    --stack-name $StackName `
    --template-file $TemplateFile `
    --capabilities CAPABILITY_NAMED_IAM `
    --profile $Profile `
    --region $Region `
    --no-cli-pager

if ($LASTEXITCODE -eq 0) {
    Write-Host "Deployment initiated successfully!" -ForegroundColor Green
} else {
    Write-Host "Deployment failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}
