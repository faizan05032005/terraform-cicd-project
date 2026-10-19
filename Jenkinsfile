pipeline {
    agent any   // Jenkins running on your Windows machine (uses cmd via 'bat')

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Terraform action to run')
        booleanParam(name: 'AUTO_APPROVE', defaultValue: false, description: 'Skip manual approval (do NOT use in prod)')
    }

    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'          // change to your region
        TF_DIR             = '.'                   // folder containing your .tf files (e.g. 'terraform')
        TF_IN_AUTOMATION   = 'true'
        TF_INPUT           = '0'
    }

    options {
        timestamps()
        disableConcurrentBuilds()                  // prevents two runs fighting over the same state
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm                       // pulls the repo configured in the Jenkins job
            }
        }

        stage('Verify Tools') {
            steps {
                bat 'terraform version'
                bat 'aws --version'
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'terrafromuser',
                                                  usernameVariable: 'AWS_acccess_key',
                                                  passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir("${env.TF_DIR}") {
                        bat 'terraform init -input=false -no-color'
                    }
                }
            }
        }

        stage('Format & Validate') {
            steps {
                dir("${env.TF_DIR}") {
                    bat 'terraform fmt -check -recursive -no-color'
                    bat 'terraform validate -no-color'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-terraform-user',
                                                  usernameVariable: 'AWS_ACCESS_KEY_ID',
                                                  passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir("${env.TF_DIR}") {
                        script {
                            if (params.ACTION == 'destroy') {
                                bat 'terraform plan -destroy -out=tfplan -input=false -no-color'
                            } else {
                                bat 'terraform plan -out=tfplan -input=false -no-color'
                            }
                        }
                    }
                }
            }
        }

        stage('Approval') {
            when { expression { return !params.AUTO_APPROVE } }
            steps {
                input message: "Review the plan above. Proceed with terraform ${params.ACTION}?",
                      ok: 'Yes, go ahead'
            }
        }

        stage('Terraform Apply / Destroy') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-terraform-user',
                                                  usernameVariable: 'AWS_ACCESS_KEY_ID',
                                                  passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir("${env.TF_DIR}") {
                        bat 'terraform apply -input=false -no-color tfplan'   // applies the exact reviewed plan
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Terraform ${params.ACTION} completed successfully."
        }
        failure {
            echo 'Pipeline failed. Check the console output above.'
        }
        always {
            dir("${env.TF_DIR}") {
                bat 'if exist tfplan del /f /q tfplan'   // plan files can contain secrets, so clean up
            }
        }
    }
}
