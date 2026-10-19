pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Terraform action to run')
        booleanParam(name: 'AUTO_APPROVE', defaultValue: false, description: 'Skip manual approval (do NOT use in prod)')
    }

    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
        TF_DIR             = '.'
        TF_IN_AUTOMATION   = 'true'
        TF_INPUT           = '0'
        // Injects credentials across all stages automatically
        AWS_ACCESS_KEY_ID     = credentials('terrafromuser')
        AWS_SECRET_ACCESS_KEY = credentials('terrafromuser')
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                sh 'terraform version'
                sh 'aws --version'
            }
        }

        stage('Terraform Init') {
            steps {
                dir("${env.TF_DIR}") {
                    sh 'terraform init -input=false -no-color'
                }
            }
        }

        stage('Format & Validate') {
            steps {
                dir("${env.TF_DIR}") {
                    sh 'terraform fmt -check -recursive -no-color'
                    sh 'terraform validate -no-color'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("${env.TF_DIR}") {
                    script {
                        if (params.ACTION == 'destroy') {
                            sh 'terraform plan -destroy -out=tfplan -input=false -no-color'
                        } else {
                            sh 'terraform plan -out=tfplan -input=false -no-color'
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
                dir("${env.TF_DIR}") {
                    sh 'terraform apply -input=false -no-color tfplan'
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
                // POSIX cleanup command for Linux
                sh 'rm -f tfplan'
            }
        }
    }
}
