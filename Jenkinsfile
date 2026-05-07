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
                        memory: "512Mi"
                        cpu: "500m"
                  - name: docker
                    image: docker:latest
                    command:
                    - sleep
                    args:
                    - "9999999"
                    volumeMounts:
                    - name: docker-sock
                      mountPath: /var/run/docker.sock
                  - name: kubectl
                    image: bitnami/kubectl:latest
                    command:
                    - sleep
                    args:
                    - infinity
                  volumes:
                  - name: docker-sock
                    hostPath:
                      path: /var/run/docker.sock
            '''
        }
    }

    environment {
        SONAR_HOME = tool "Sonar"
    }

    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
        string(name: 'BACKEND_DOCKER_TAG',  defaultValue: '', description: 'Setting docker image for latest push')
    }

    stages {

        // ── 1. Validate ──────────────────────────────────────────────────
        // Runs in jnlp (default) — no docker/kubectl needed
        stage("Validate Parameters") {
            steps {
                script {
                    if (params.FRONTEND_DOCKER_TAG == '' || params.BACKEND_DOCKER_TAG == '') {
                        error("FRONTEND_DOCKER_TAG and BACKEND_DOCKER_TAG must be provided.")
                    }
                }
            }
        }

        // ── 2. Workspace Cleanup ─────────────────────────────────────────
        // Runs in jnlp — cleanWs() is a Jenkins plugin call, no container needed
        stage("Workspace cleanup") {
            steps {
                script {
                    cleanWs()
                }
            }
        }

        // ── 3. Git Checkout ──────────────────────────────────────────────
        // Runs in jnlp — shared library git function, no container needed
        stage('Git: Code Checkout') {
            steps {
                script {
                    code_checkout("https://github.com/Zaid-983/Wanderlust-Mega-Project", "main")
                }
            }
        }

        // ── 4. Trivy Scan ────────────────────────────────────────────────
        // Runs in jnlp — trivy is installed on the agent image
        stage("Trivy: Filesystem scan") {
            steps {
                script {
                    trivy_scan()
                }
            }
        }

        // ── 5. OWASP Dependency Check ────────────────────────────────────
        // Runs in jnlp — OWASP plugin runs inside Jenkins agent
        stage("OWASP: Dependency check") {
            steps {
                script {
                    owasp_dependency()
                }
            }
        }

        // ── 6. SonarQube Analysis ────────────────────────────────────────
        // Runs in jnlp — SonarQube scanner uses SONAR_HOME tool path
        stage("SonarQube: Code Analysis") {
            steps {
                script {
                    sonarqube_analysis("Sonar", "wanderlust", "wanderlust")
                }
            }
        }

        // ── 7. SonarQube Quality Gate ────────────────────────────────────
        // Runs in jnlp — waits for SonarQube webhook callback
        stage("SonarQube: Code Quality Gates") {
            steps {
                script {
                    sonarqube_code_quality()
                }
            }
        }

        // ── 8. Env Setup (parallel) ──────────────────────────────────────
        // Runs shell scripts — jnlp can run bash, no special container needed
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

        // ── 9. Docker Build ──────────────────────────────────────────────
        // MUST run in docker container — needs docker CLI to build images
        stage("Docker: Build Images") {
            steps {
                container('docker') {                          // ← switch to docker container
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

        // ── 10. Docker Push ──────────────────────────────────────────────
        // MUST run in docker container — needs docker CLI to push to DockerHub
        stage("Docker: Push to DockerHub") {
            steps {
                container('docker') {                          // ← switch to docker container
                    script {
                        docker_push("wanderlust-backend-beta",  "${params.BACKEND_DOCKER_TAG}",  "zaidjamal")
                        docker_push("wanderlust-frontend-beta", "${params.FRONTEND_DOCKER_TAG}", "zaidjamal")
                    }
                }
            }
        }
    }

    // ── Post: Trigger CD Pipeline ────────────────────────────────────────
    // Runs in jnlp — archiving artifacts and triggering downstream job
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