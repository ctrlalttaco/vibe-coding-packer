pipeline {
    agent any
    parameters {
        choice(name: 'DISTRO', choices: ['amazon-linux-2', 'amazon-linux-2023', 'rhel-8', 'rhel-9', 'rocky-8', 'rocky-9', 'ubuntu-22', 'ubuntu-24'], description: 'Linux distribution to build (leave as is for all)')
        choice(name: 'ARCH', choices: ['x86_64', 'arm64'], description: 'CPU architecture to build (leave as is for all)')
    }
    triggers {
        cron('0 1 * * 1')
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        parallelsAlwaysFailFast()
        disableConcurrentBuilds()
    }
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION    = 'us-east-1'
    }
    stages {
        stage('Init') {
            steps {
                sh 'packer init .'
            }
        }
        stage('Validate') {
            steps {
                sh 'packer validate build.pkr.hcl'
            }
        }
        stage('Matrix Build AMIs') {
            matrix {
                axes {
                    axis {
                        name: 'DISTRO'
                        values: params.DISTRO == '' ? ['ubuntu-22-04', 'ubuntu-24-04', 'rhel-8', 'rhel-9', 'amazon-linux-2', 'amazon-linux-2023', 'rocky-8', 'rocky-9'] : [params.DISTRO]
                    }
                    axis {
                        name: 'ARCH'
                        values: params.ARCH == '' ? ['x86_64', 'arm64'] : [params.ARCH]
                    }
                }
                stages {
                    stage('Build') {
                        agent any
                        options { lock(resource: 'packer-ami', quantity: 2) }
                        steps {
                            sh "packer build -var 'distro=${DISTRO}' -var 'arch=${ARCH}' build.pkr.hcl"
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}

