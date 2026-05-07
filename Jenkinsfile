@Library('Shared') _

pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                metadata:
                  namespace: jenkins
                spec:
                  serviceAccountName: jenkins-agent-sa
                  containers:
                  - name: jnlp
                    image: jenkins/inbound-agent:latest
                    resources:
                      requests:
                        memory: "256Mi"
                        cpu: "100m"
                      limits:
                        memory: "2Gi"        
                        cpu: "1000m"
                    volumeMounts:
                - name: owasp-cache                                    
                  mountPath: /var/lib/jenkins/caches/dependency-check
                  
                  - name: docker
                    image: docker:latest
                    command:
                    - sleep
                    args:
                    - "9999999"
                    volumeMounts:
                    - name: docker-sock
                      mountPath: /var/run/docker.sock
                  volumes:
                  - name: docker-sock
                    hostPath:
                      path: /var/run/docker.sock
            '''
        }
    }

    environment {
        SONAR_HOME = tool "Sonar"
        SONAR_SCANNER_OPTS = "-Xmx1024m -Xms256m" 
    }

    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
        string(name: 'BACKEND_DOCKER_TAG',  defaultValue: '', description: 'Setting docker image for latest push')
    }

    stages {

        stage("Validate Parameters") {
            steps {
                script {
                    if (params.FRONTEND_DOCKER_TAG == '' || params.BACKEND_DOCKER_TAG == '') {
                        error("FRONTEND_DOCKER_TAG and BACKEND_DOCKER_TAG must be provided.")
                    }
                }
            }
        }

        stage("Workspace cleanup") {
            steps {
                script { cleanWs() }
            }
        }

        stage('Git: Code Checkout') {
            steps {
                script {
                    code_checkout("https://github.com/Zaid-983/Wanderlust-Mega-Project", "main")
                }
            }
        }

        // ── Install Trivy on jnlp container ─────────────────────────────
        stage("Trivy: Install and Filesystem scan") {
            steps {
                container('docker') {
                    sh '''
                        echo "Installing dependencies..."
                        apk add --no-cache curl wget bash

                        echo "Installing Trivy..."
                        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

                        echo "Verifying Trivy installation..."
                        trivy --version

                        echo "Running Trivy filesystem scan..."
                        trivy fs --format table -o trivy-report.xml .

                        echo "Trivy scan completed!"
                    '''
                }
            }
        }

        stage("OWASP: Dependency check") {
            steps {
                    script {
                        owasp_dependency()
                 }
                 
            }
        }

        stage("SonarQube: Code Analysis") {
            steps {
                script {
                    sonarqube_analysis("Sonar", "wanderlust", "wanderlust")
                }
            }
        }

        stage("SonarQube: Code Quality Gates") {
            steps {
                script {
                    sonarqube_code_quality()
                }
            }
        }

        stage('Exporting environment variables') {
            parallel {
                stage("Backend env setup") {
                    steps {
                        script {
                            dir("Automations") {
                                sh "bash updatebackendnew.sh"
                            }
                        }
                    }
                }
                stage("Frontend env setup") {
                    steps {
                        script {
                            dir("Automations") {
                                sh "bash updatefrontendnew.sh"
                            }
                        }
                    }
                }
            }
        }

        stage("Docker: Build Images") {
            steps {
                container('docker') {
                    script {
                        dir('backend') {
                            docker_build("wanderlust-backend-beta", "${params.BACKEND_DOCKER_TAG}", "zaidjamal")
                        }
                        dir('frontend') {
                            docker_build("wanderlust-frontend-beta", "${params.FRONTEND_DOCKER_TAG}", "zaidjamal")
                        }
                    }
                }
            }
        }

        stage("Docker: Push to DockerHub") {
            steps {
                container('docker') {
                    script {
                        docker_push("wanderlust-backend-beta",  "${params.BACKEND_DOCKER_TAG}",  "zaidjamal")
                        docker_push("wanderlust-frontend-beta", "${params.FRONTEND_DOCKER_TAG}", "zaidjamal")
                    }
                }
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: '*.xml', followSymlinks: false
            build job: "Wanderlust-CD", parameters: [
                string(name: 'FRONTEND_DOCKER_TAG', value: "${params.FRONTEND_DOCKER_TAG}"),
                string(name: 'BACKEND_DOCKER_TAG',  value: "${params.BACKEND_DOCKER_TAG}")
            ]
        }
    }
}