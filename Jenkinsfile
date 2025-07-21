def distros = ['amazon-linux-2', 'amazon-linux-2-ecs', 'amazon-linux-2-eks', 'amazon-linux-2023', 'amazon-linux-2023-ecs', 'amazon-linux-2023-eks', 'rhel-8', 'rhel-8-ws', 'rhel-9', 'rhel-9-ws', 'rocky-8', 'rocky-8-ws', 'rocky-9', 'rocky-9-ws', 'ubuntu-22', 'ubuntu-24']
def architectures = ['x86_64', 'arm64']
def k8s_versions = ['1.29', '1.30', '1.31', '1.32', '1.33']
def instance_type_overrides = ['c5.large', 'c5.xlarge', 'c5.2xlarge', 'c6g.large', 'c6g.xlarge', 'c6g.2xlarge']

pipeline {
    agent any
    // Parameters that can be set in the Jenkins UI
    parameters {
        choice(name: 'DISTRO', choices: ['all'] + distros, description: 'Linux distribution to build (leave empty for all)')
        choice(name: 'ARCH', choices: ['all'] + architectures, description: 'CPU architecture to build (leave empty for all)')
        choice(name: 'K8S_VERSION', choices: ['all'] + k8s_versions, description: 'Kubernetes version to build (leave empty for all)')
        booleanParam(name: 'ENABLE_FIPS', defaultValue: false, description: 'Enable FIPS mode for security compliance')
        booleanParam(name: 'ENFORCE_IMDSV2', defaultValue: true, description: 'Enforce IMDSv2 for enhanced security')
        choice(name: 'INSTANCE_TYPE_OVERRIDE', choices: ['all'] + instance_type_overrides, description: 'Override instance type for builds (leave empty for auto-selection)')
    }
    triggers {
        // Run every Monday at 1:00 AM UTC for full builds
        cron('H 1 * * 1')
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        parallelsAlwaysFailFast()
        disableConcurrentBuilds()
        timeout(time: 4, unit: 'HOURS')  // Increased timeout for security builds
        timestamps()
        ansiColor('xterm')
        skipDefaultCheckout(true)
    }
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION    = 'us-east-1'
        PACKER_LOG            = '1'
        PACKER_LOG_PATH       = 'packer.log'
        CHECKPOINT_DISABLE    = '1'
    }
    stages {
        stage('Pre-build Setup') {
            steps {
                script {
                    echo "=== Build Configuration ==="
                    echo "FIPS Enabled: ${params.ENABLE_FIPS}"
                    echo "IMDSv2 Enforced: ${params.ENFORCE_IMDSV2}"
                    echo "Parallel Builds: ${params.PARALLEL_BUILDS}"
                    if (params.INSTANCE_TYPE_OVERRIDE) {
                        echo "Instance Type Override: ${params.INSTANCE_TYPE_OVERRIDE}"
                    }
                    echo "=========================="

                    // Cleanup workspace
                    cleanWs()
                    // Checkout code
                    checkout scm
                    sh "git checkout vibe_coding"
                }
            }
        }
        stage('Validate Configuration') {
            parallel {
                // stage('Packer Init & Validate') {
                //     steps {
                //         sh 'packer init .'
                //         sh 'packer validate build.pkr.hcl'
                //     }
                // }
                // stage('Ansible Syntax Check') {
                //     steps {
                //         sh 'ansible-playbook --syntax-check ansible/playbook.yml'
                //     }
                // }
                stage('Scripts Check') {
                    steps {
                        sh 'bash -n scripts/prerequisites.sh'
                        sh 'bash -n scripts/cleanup.sh'
                    }
                }
            }
        }
        // Dynamic parallel builds for each distro, architecture, and k8s version
        stage('Parallel AMI Builds') {
            steps {
                script {
                    def buildMatrix = [:]
                    def filtered_distros = []
                    def filtered_architectures = params.ARCH == 'all' ? architectures : [params.ARCH]
                    def filtered_k8s_versions = params.K8S_VERSION == 'all' ? k8s_versions : [params.K8S_VERSION]

                    if (params.DISTRO == 'all') {
                        filtered_distros = distros
                    } else {
                        filtered_distros = [params.DISTRO]
                    }

                    for (distro in filtered_distros) {
                        def isEks = distro.contains("-eks")
                        def k8s_versions_to_use = isEks ? filtered_k8s_versions : [null]
                        for (arch in filtered_architectures) {
                            for (k8s_version in k8s_versions_to_use) {
                                // Skip non-EKS distros if k8s_version is set
                                if (!isEks && k8s_version != null) {
                                    continue
                                }
                                // Skip EKS distros if k8s_version is not set
                                if (isEks && k8s_version == null) {
                                    continue
                                }
                                // Do not allow amazon-linux-2-eks to build on Kubernetes versions greater than 1.32
                                if (distro == 'amazon-linux-2-eks' && k8s_version && k8s_version > '1.32') {
                                    echo "Skipping ${distro}-${arch}-${k8s_version} - Kubernetes version ${k8s_version} is not supported"
                                    continue
                                }
                                def stageName = isEks ? "Build ${distro}-${arch}-${k8s_version}" : "Build ${distro}-${arch}"
                                buildMatrix[stageName] = {
                                    stage(stageName) {
                                        def buildCmd = "packer build"
                                        buildCmd += " -var 'distro=${distro}'"
                                        buildCmd += " -var 'arch=${arch}'"
                                        buildCmd += " -var 'enable_fips=${params.ENABLE_FIPS}'"
                                        if (isEks) {
                                            buildCmd += " -var 'k8s_version=${k8s_version}'"
                                        }
                                        if (params.INSTANCE_TYPE_OVERRIDE) {
                                            buildCmd += " -var 'instance_type_override=${params.INSTANCE_TYPE_OVERRIDE}'"
                                        }
                                        buildCmd += " build.pkr.hcl"
                                        echo "Building ${distro} for ${arch}${isEks ? " and ${k8s_version}" : ""}..."
                                        // sh buildCmd
                                    }
                                }
                            }
                        }
                    }
                    parallel buildMatrix
                }
            }
        }
        stage('Security Validation') {
            steps {
                script {
                    echo "=== Security Build Summary ==="
                    if (fileExists('manifest.json')) {
                        def manifest = readJSON file: 'manifest.json'
                        manifest.builds.each { build ->
                            echo "AMI: ${build.custom_data.ami_name}"
                            echo "  - FIPS Enabled: ${build.custom_data.fips_enabled}"
                            echo "  - IMDSv2 Enforced: ${build.custom_data.imdsv2_enforced}"
                            echo "  - Build Duration: ${build.custom_data.build_duration}s"
                        }
                    }
                    echo "=============================="
                }
            }
        }
    }
    post {
        cleanup {
            script {
                // Clean up workspace for security
                if (getContext(hudson.FilePath)) {
                    cleanWs()
                }
            }
        }
        success {
            script {
                def buildSummary = "✅ AMI Build Successful\n"
                buildSummary += "Configuration:\n"
                buildSummary += "- FIPS: ${params.ENABLE_FIPS}\n"
                buildSummary += "- Parallel Builds: ${params.PARALLEL_BUILDS}\n"
                
                if (params.DISTRO) {
                    buildSummary += "- Distro: ${params.DISTRO}\n"
                }
                if (params.ARCH) {
                    buildSummary += "- Architecture: ${params.ARCH}\n"
                }
                
                echo buildSummary
                
                // Send notification if configured
                // slackSend(channel: '#infrastructure', message: buildSummary)
            }
        }
        failure {
            script {
                def failureMessage = "❌ AMI Build Failed\n"
                failureMessage += "Build: ${env.BUILD_URL}\n"
                failureMessage += "Check logs for details."
                
                echo failureMessage
                
                // Send failure notification if configured
                // slackSend(channel: '#infrastructure', message: failureMessage, color: 'danger')
            }
        }
        unstable {
            echo "⚠️ AMI Build completed with warnings"
        }
    }
}
