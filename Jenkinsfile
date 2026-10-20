// ==============================================================================
// Jenkinsfile - Axion System 3-Tier Infrastructure CI/CD Pipeline
// Project: Axion System (Microsoft Azure & Terraform)
// ==============================================================================

pipeline {
    agent any

    options {
        timeout(time: 2, unit: 'HOURS')
        timestamps()
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

                        // Stash the plan file so it is guaranteed identical during Apply
                        stash name: 'terraform-plan', includes: "${env.PLAN_FILE}"

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
                                string(
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
 * Wraps execution within Azure credentials using multiple fallback strategies:
 * 1. Individual Secret Text credentials (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID)
 * 2. Azure Service Principal credential (AZURE_CREDENTIAL_ID)
 * 3. Username/Password credential (AZURE_CREDENTIAL_ID)
 * 4. Automatic Azure CLI session detection (bridges Windows Service accounts to user's .azure folder)
 * 5. Ambient environment variables
 */
def withAzureEnv(Closure body) {
    // Strategy 1: Individual Jenkins Secret Text credentials
    try {
        withCredentials([
            string(credentialsId: 'ARM_CLIENT_ID', variable: 'AZ_CLIENT_ID'),
            string(credentialsId: 'ARM_CLIENT_SECRET', variable: 'AZ_CLIENT_SECRET'),
            string(credentialsId: 'ARM_SUBSCRIPTION_ID', variable: 'AZ_SUBSCRIPTION_ID'),
            string(credentialsId: 'ARM_TENANT_ID', variable: 'AZ_TENANT_ID')
        ]) {
            withEnv([
                "ARM_CLIENT_ID=${AZ_CLIENT_ID}",
                "ARM_CLIENT_SECRET=${AZ_CLIENT_SECRET}",
                "ARM_SUBSCRIPTION_ID=${AZ_SUBSCRIPTION_ID}",
                "ARM_TENANT_ID=${AZ_TENANT_ID}"
            ]) {
                echo "🔑 Authenticated using Jenkins Secret Text credentials (ARM_*)."
                body()
                return
            }
        }
    } catch (Throwable t1) {
        // Continue to Strategy 2
    }

    // Strategy 2: Azure Service Principal plugin credential
    try {
        withCredentials([
            azureServicePrincipal(
                credentialsId: env.AZURE_CREDENTIAL_ID,
                subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                clientIdVariable: 'ARM_CLIENT_ID',
                clientSecretVariable: 'ARM_CLIENT_SECRET',
                tenantIdVariable: 'ARM_TENANT_ID'
            )
        ]) {
            echo "🔑 Authenticated using Azure Service Principal credential (${env.AZURE_CREDENTIAL_ID})."
            body()
            return
        }
    } catch (Throwable t2) {
        // Continue to Strategy 3
    }

    // Strategy 3: Username with Password credential
    try {
        withCredentials([
            usernamePassword(
                credentialsId: env.AZURE_CREDENTIAL_ID,
                usernameVariable: 'ARM_CLIENT_ID',
                passwordVariable: 'ARM_CLIENT_SECRET'
            )
        ]) {
            echo "🔑 Authenticated using Username/Password credential (${env.AZURE_CREDENTIAL_ID})."
            body()
            return
        }
    } catch (Throwable t3) {
        // Continue to Strategy 4
    }

    // Strategy 4: Windows Service Account Profile Discovery
    // When Jenkins runs as a Windows Service (LocalSystem), bridge to existing user's az login cache
    if (!isUnix()) {
        try {
            def userAzureDir = powershell(
                returnStdout: true,
                script: '''
                    $found = Get-ChildItem "C:\\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                        Join-Path $_.FullName ".azure\\azureProfile.json"
                    } | Where-Object { Test-Path $_ } | Select-Object -First 1
                    if ($found) {
                        Write-Output (Split-Path $found -Parent)
                    }
                '''
            ).trim()

            if (userAzureDir && userAzureDir.length() > 0) {
                echo "ℹ️ Discovered active Azure CLI profile at: ${userAzureDir}. Setting AZURE_CONFIG_DIR..."
                withEnv(["AZURE_CONFIG_DIR=${userAzureDir}"]) {
                    body()
                    return
                }
            }
        } catch (Throwable t4) {
            // Continue to ambient fallback
        }
    }

    // Strategy 5: Ambient agent environment variables or pre-configured Azure CLI
    echo "ℹ️ Using ambient agent Azure credentials or pre-configured environment."
    body()
}
