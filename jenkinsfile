pipeline {

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
    } 
    environment {
        // credenciales 

        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }

   agent  any
    stages {
        
        stage('Plan') {
            steps {
                script {


                    dir("IAC/infra/tf") {
                        sh 'terraform init'
                        sh "terraform plan -out tfplan"

                        sh 'terraform show -no-color tfplan > tfplan.txt'
                    }
                }
            }
        }
        
        stage('Approval') {
           when {
               not {
                   equals expected: true, actual: params.autoApprove
               }
           }

           steps {
               script {
  

                   def plan = readFile 'IAC/infra/tf/tfplan.txt' 
                   
                   input message: "Do you want to apply the plan?",
                   parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
               }
           }
       }

        stage('Apply') {
            steps {
                script {

                    dir("IAC/infra/tf") {
                        sh "terraform apply -input=false tfplan"
                    }
                }
            }
        }
    }

  }