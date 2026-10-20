// ==============================================================================
// Jenkinsfile - Axion System 3-Tier Infrastructure CI/CD Pipeline
// Project: Axion System (Microsoft Azure & Terraform)
// ==============================================================================

pipeline {
    agent any

    options {
        timeout(time: 2, unit: 'HOURS')
        timestamps()
        ansiColor('xterm')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '10'))
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy', 'lint-only'],
            description: 'Select the Terraform action to execute.'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Target infrastructure environment.'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'If unchecked, pipeline pauses for manual review and approval before Apply/Destroy.'
        )
        booleanParam(
            name: 'ENABLE_TFLINT',
            defaultValue: true,
            description: 'Execute TFLint ruleset validation during code quality check.'
        )
    }

    environment {
        TF_IN_AUTOMATION    = 'true'
        TF_VAR_environment = "${params.ENVIRONMENT ?: 'dev'}"
        PLAN_FILE           = 'tfplan'
        
        // Optional: Azure Service Principal credentials ID configured in:
        // Jenkins -> Manage Jenkins -> Credentials -> System -> Global credentials
        // Set this ID to match your Jenkins credential ID (e.g., 'azure-sp' or 'azure-credentials')
        AZURE_CREDENTIAL_ID = 'azure-sp-credentials'
    }

    stages {
        // ======================================================================
        // STAGE 1: ENVIRONMENT & RUNTIME INSPECTION
        // ======================================================================
        stage('Environment Discovery') {
            steps {
                script {
                    echo "=========================================================="
                    echo "🚀 Starting Axion System Pipeline"
                    echo "Action:       ${params.ACTION}"
                    echo "Environment:  ${params.ENVIRONMENT}"
                    echo "Auto-Approve: ${params.AUTO_APPROVE}"
                    echo "Node OS:      ${isUnix() ? 'Linux / Unix' : 'Windows'}"
                    echo "=========================================================="

                    runCmd("terraform version")
                    try {
                        runCmd("az version")
                    } catch (Exception e) {
                        echo "⚠️ Azure CLI not found in PATH or not installed; relying on Service Principal / environment variables."
                    }
                }
            }
        }

        // ======================================================================
        // STAGE 2: CONTINUOUS INTEGRATION (Lint, Format & Validate)
        // ======================================================================
        stage('Terraform CI (Lint & Validate)') {
            steps {
                script {
                    echo "🔍 Step 2.1: Checking Terraform formatting..."
                    runCmd("terraform fmt -check -recursive")

                    echo "🔍 Step 2.2: Initializing Terraform for syntax validation (backend disabled)..."
                    runCmd("terraform init -backend=false")

                    echo "🔍 Step 2.3: Validating Terraform syntax and module references..."
                    runCmd("terraform validate")

                    if (params.ENABLE_TFLINT) {
                        echo "🔍 Step 2.4: Running TFLint..."
                        try {
                            runCmd("tflint --version")
                            runCmd("tflint --init")
                            runCmd("tflint --recursive")
                        } catch (Exception e) {
                            echo "⚠️ TFLint check completed with warnings or tflint binary was not available: ${e.message}"
                        }
                    }
                }
            }
        }

        // ======================================================================
        // STAGE 3: TERRAFORM INIT (With Provider & Backend Configuration)
        // ======================================================================
        stage('Terraform Init') {
            when {
                expression { params.ACTION != 'lint-only' }
            }
            steps {
                script {
                    withAzureEnv {
                        echo "⚙️ Initializing Terraform working directory..."
                        runCmd("terraform init -input=false")
                    }
                }
            }
        }

        // ======================================================================
        // STAGE 4: TERRAFORM PLAN
        // ======================================================================
        stage('Terraform Plan') {
            when {
                expression { params.ACTION in ['plan', 'apply', 'destroy'] }
            }
            steps {
                script {
                    withAzureEnv {
                        if (params.ACTION == 'destroy') {
                            echo "📋 Generating Destroy Plan for Axion System (${params.ENVIRONMENT})..."
                            runCmd("terraform plan -destroy -out=${env.PLAN_FILE} -input=false")
                        } else {
                            echo "📋 Generating Execution Plan for Axion System (${params.ENVIRONMENT})..."
                            runCmd("terraform plan -out=${env.PLAN_FILE} -input=false")
                        }

                        // Stash the plan and module state so it's guaranteed identical during Apply
                        stash name: 'terraform-plan', includes: "${env.PLAN_FILE}, .terraform/**, .terraform.lock.hcl"

                        // Archive plan artifact in Jenkins build history
                        archiveArtifacts artifacts: "${env.PLAN_FILE}", fingerprint: true, allowEmptyArchive: true
                    }
                }
            }
        }

        // ======================================================================
        // STAGE 5: MANUAL APPROVAL GATE
        // ======================================================================
        stage('Manual Approval Gate') {
            when {
                allOf {
                    expression { params.ACTION in ['apply', 'destroy'] }
                    expression { !params.AUTO_APPROVE }
                }
            }
            steps {
                script {
                    echo "⏸️ Waiting for operator approval..."
                    timeout(time: 24, unit: 'HOURS') {
                        input(
                            id: 'ProceedDeployment',
                            message: "Approve '${params.ACTION.toUpperCase()}' on Axion System [${params.ENVIRONMENT.toUpperCase()}]?",
                            ok: "Approve & Execute ${params.ACTION.toUpperCase()}",
                            parameters: [
                                text(
                                    name: 'APPROVAL_NOTES',
                                    defaultValue: 'Approved for deployment after reviewing plan artifact.',
                                    description: 'Reviewer comments or ticket reference'
                                )
                            ]
                        )
                    }
                    echo "✅ Approval received! Proceeding with ${params.ACTION}..."
                }
            }
        }

        // ======================================================================
        // STAGE 6: CONTINUOUS DEPLOYMENT (Apply or Destroy)
        // ======================================================================
        stage('Terraform Apply / Destroy') {
            when {
                expression { params.ACTION in ['apply', 'destroy'] }
            }
            steps {
                script {
                    withAzureEnv {
                        echo "📦 Unstashing execution plan..."
                        unstash 'terraform-plan'

                        if (params.ACTION == 'apply') {
                            echo "🚀 Applying Terraform Execution Plan to Microsoft Azure..."
                            runCmd("terraform apply -input=false ${env.PLAN_FILE}")

                            echo "=========================================================="
                            echo "🎉 Deployment Successful! Querying Infrastructure Outputs:"
                            echo "=========================================================="
                            runCmd("terraform output -no-color")
                        } else if (params.ACTION == 'destroy') {
                            echo "💥 Executing Infrastructure Destruction on Microsoft Azure..."
                            runCmd("terraform apply -input=false ${env.PLAN_FILE}")
                            echo "🧹 Teardown completed successfully."
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "🏁 Pipeline run finished for Action: ${params.ACTION} [Environment: ${params.ENVIRONMENT}]"
                // Clean up sensitive plan file from the active workspace
                if (isUnix()) {
                    sh "rm -f ${env.PLAN_FILE} || true"
                } else {
                    powershell "if (Test-Path '${env.PLAN_FILE}') { Remove-Item -Force '${env.PLAN_FILE}' }"
                }
            }
        }
        success {
            echo "✅ Axion System pipeline executed successfully!"
        }
        unstable {
            echo "⚠️ Axion System pipeline finished in an UNSTABLE state. Please review logs above."
        }
        failure {
            echo "❌ Pipeline failed! Check the console output for Terraform or Azure authentication errors."
        }
    }
}

// ==============================================================================
// HELPER FUNCTIONS
// ==============================================================================

/**
 * Executes a shell command using 'sh' on Unix/Linux nodes or 'powershell' on Windows nodes.
 */
def runCmd(String command) {
    if (isUnix()) {
        sh command
    } else {
        powershell command
    }
}

/**
 * Wraps execution within Azure credentials if available in Jenkins Credential Store,
 * otherwise falls back gracefully to ambient environment variables or Azure CLI session.
 */
def withAzureEnv(Closure body) {
    try {
        // Supports Azure Service Principal credentials (ClientId, ClientSecret, TenantId, SubscriptionId)
        withCredentials([
            azureServicePrincipal(
                credentialsId: env.AZURE_CREDENTIAL_ID,
                subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                clientIdVariable: 'ARM_CLIENT_ID',
                clientSecretVariable: 'ARM_CLIENT_SECRET',
                tenantIdVariable: 'ARM_TENANT_ID'
            )
        ]) {
            body()
        }
    } catch (Exception e) {
        // If the azureServicePrincipal credential plugin/id is not found, try usernamePassword or ambient environment
        try {
            withCredentials([
                usernamePassword(
                    credentialsId: env.AZURE_CREDENTIAL_ID,
                    usernameVariable: 'ARM_CLIENT_ID',
                    passwordVariable: 'ARM_CLIENT_SECRET'
                )
            ]) {
                body()
            }
        } catch (Exception ex) {
            // Fall back to ambient environment variables or pre-authenticated Azure CLI agent
            echo "ℹ️ Using ambient agent Azure credentials or pre-configured environment."
            body()
        }
    }
}
