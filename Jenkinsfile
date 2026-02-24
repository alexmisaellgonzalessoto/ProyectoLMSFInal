pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 120, unit: 'MINUTES')
        timestamps()
    }

    parameters {
        choice(
            name: 'targetEnvironment',
            choices: ['dev', 'staging', 'prod'],
            description: 'Ambiente objetivo para despliegue'
        )
        string(
            name: 'awsAccountId',
            defaultValue: '218085830508',
            description: 'ID de cuenta AWS para ECR'
        )
        booleanParam(
            name: 'autoApprove',
            defaultValue: false,
            description: 'Aplicar Terraform sin aprobacion manual'
        )
        booleanParam(
            name: 'buildImages',
            defaultValue: true,
            description: 'Construir y publicar imagenes Docker (frontend/backend)'
        )
        booleanParam(
            name: 'deployServices',
            defaultValue: true,
            description: 'Actualizar servicios ECS y ejecutar health checks'
        )
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_SESSION_TOKEN     = credentials('AWS_SESSION_TOKEN')
        AWS_DEFAULT_REGION    = 'us-east-1'
        AWS_REGION            = 'us-east-1'
        TF_IN_AUTOMATION      = 'true'
    }

    stages {
        stage('Preflight') {
            steps {
                sh '''
                    set -e
                    for tool in terraform aws node npm ansible-playbook docker; do
                      command -v "$tool" >/dev/null 2>&1 || {
                        echo "Falta herramienta requerida: $tool"
                        exit 1
                      }
                    done
                '''
            }
        }

        stage('CI Backend') {
            steps {
                dir('back') {
                    sh '''
                        set -e
                        if [ -f package-lock.json ]; then
                          npm ci
                        else
                          npm install
                        fi
                        npm run lint
                        npm test
                    '''
                }
            }
        }

        stage('CI Frontend') {
            steps {
                dir('front') {
                    sh '''
                        set -e
                        test -s index.html
                        test -s dockerfile
                        grep -Eiq "<!doctype html>" index.html
                    '''
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('infra/terraform') {
                    sh '''
                        set -e
                        terraform fmt -check -recursive
                        terraform init -input=false
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('infra/terraform') {
                    sh """
                        set -e
                        terraform plan -input=false -var="environment=${params.targetEnvironment}" -out=tfplan
                        terraform show -no-color tfplan > tfplan.txt
                    """
                }
            }
        }

        stage('Aprobacion Manual') {
            when {
                expression { !params.autoApprove }
            }
            steps {
                script {
                    def plan = readFile('infra/terraform/tfplan.txt')
                    input(
                        message: "Confirma apply de Terraform para ${params.targetEnvironment}",
                        parameters: [
                            text(name: 'ResumenPlan', description: 'Revision del plan', defaultValue: plan)
                        ]
                    )
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('infra/terraform') {
                    sh 'terraform apply -input=false tfplan'
                }
            }
        }

        stage('Build y Push Docker') {
            when {
                expression { params.buildImages }
            }
            steps {
                dir('infra/ansible') {
                    sh """
                        set -e
                        ansible-galaxy collection install -r requirements.yml
                        AWS_ACCOUNT_ID=${params.awsAccountId} ansible-playbook playbook.yaml \\
                          -e "env=${params.targetEnvironment}" \\
                          -e "build_frontend=true" \\
                          -e "build_backend=true" \\
                          -e "deploy_frontend=false" \\
                          -e "deploy_backend=false" \\
                          --tags "terraform,docker"
                    """
                }
            }
        }

        stage('Deploy ECS + Healthcheck') {
            when {
                expression { params.deployServices }
            }
            steps {
                dir('infra/ansible') {
                    sh """
                        set -e
                        AWS_ACCOUNT_ID=${params.awsAccountId} ansible-playbook playbook.yaml \\
                          -e "env=${params.targetEnvironment}" \\
                          -e "build_frontend=false" \\
                          -e "build_backend=false" \\
                          -e "deploy_frontend=true" \\
                          -e "deploy_backend=true" \\
                          --tags "terraform,database,deploy,healthcheck"
                    """
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'infra/terraform/tfplan.txt', allowEmptyArchive: true
            archiveArtifacts artifacts: 'infra/terraform/tfplan', allowEmptyArchive: true
        }
        failure {
            echo 'Pipeline fallida. Revisar logs de etapa y tfplan.'
        }
        success {
            echo "Pipeline completada para ambiente ${params.targetEnvironment}"
        }
    }
}
