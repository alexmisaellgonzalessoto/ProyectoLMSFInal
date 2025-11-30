#No se si pushear mis scripts porque me sale un warning 
#!/bin/bash
set -e
ENVIRONMENT=${1:-dev}
echo "Salud de la infraestructura en el ambiente: $ENVIRONMENT"

#Obtener alb dns
ALB_DNS=$(cd terraform && terraform output -raw alb_dns_name)

echo -n "Salud del ALB:"
if curl -sf http://$ALB_DNS/healthz > /dev/null; then
    echo "TODO BIEN jajsjs"
else
    echo "HAY PROBLEMAS :v"
fi
#backend api
echo -n "Backend API: "
if curl -sf "http://$ALB_DNS/api/health" > /dev/null; then
    echo "TODO BIEN jajsjs"
else
    echo "HAY PROBLEMAS :v"
fi
#ecs service
CLUSTER=$(cd terraform && terraform output -raw ecs_cluster_name)

for SERVICE in "lms-frontend-service-$ENVIRONMENT" "lms-backend-service-$ENVIRONMENT"; do
    echo -n "$SERVICE: "
    RUNNING=$(aws ecs describe-services \
        --cluster $CLUSTER \
        --services $SERVICE \
        --query 'services[0].runningCount' \
        --output text)
    DESIRED=$(aws ecs describe-services \
        --cluster $CLUSTER \
        --services $SERVICE \
        --query 'services[0].desiredCount' \
        --output text)
    
    if [ "$RUNNING" == "$DESIRED" ]; then
        echo "$RUNNING/$DESIRED tasks running"
    else
        echo "$RUNNING/$DESIRED tasks running"
    fi
done
#SALUD AURORA
echo -n "Aurora Database: "
DB_CLUSTER=$(cd terraform && terraform output -raw aurora_cluster_endpoint)
DB_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id lms/aurora/credentials-$ENVIRONMENT \
    --query SecretString \
    --output text | jq -r .password)

if mysql -h "$DB_CLUSTER" -u lmsadmin -p"$DB_SECRET" -e "SELECT 1" &> /dev/null; then
    echo "TODO BIEN jasjajs"
else
    echo "TODO MAL XD"
fi

echo ""
echo "URL: http://$ALB_DNS"
