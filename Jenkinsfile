pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {
        booleanParam(
            name: 'FORCE_TEST_FAILURE',
            defaultValue: false,
            description: 'Intentional unit-test CI failure drill'
        )
    }

    environment {
        APP_DIR = 'app'
        IMAGE_NAME = 'cloud-devops-lab-app'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm

                sh '''
                    echo "Commit:"
                    git rev-parse --short HEAD

                    echo "Branch:"
                    git branch --show-current || true
                '''
            }
        }

        stage('Verify Tooling') {
            steps {
                sh '''
                    git --version
                    node --version
                    npm --version
                    docker --version
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                dir("${APP_DIR}") {
                    sh '''
                        test -f package-lock.json
                        npm ci
                    '''
                }
            }
        }

        stage('Lint') {
            steps {
                dir("${APP_DIR}") {
                    sh 'npm run lint'
                }
            }
        }

        stage('Unit Tests') {
            steps {
                dir("${APP_DIR}") {
                    sh 'npm test'
                }

                script {
                    if (params.FORCE_TEST_FAILURE) {
                        error(
                            'Intentional CI failure requested for Phase 10 validation'
                        )
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'

                    withSonarQubeEnv('SonarQube') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build \
                        --label ci.project=cloud-devops-lab \
                        --label ci.build="${BUILD_NUMBER}" \
                        -t "${IMAGE_NAME}:ci-${BUILD_NUMBER}" \
                        "${APP_DIR}"

                    mkdir -p ci-artifacts

                    docker image inspect \
                        "${IMAGE_NAME}:ci-${BUILD_NUMBER}" \
                        > ci-artifacts/docker-image.json
                '''
            }
        }
    }

    post {

        success {
            echo 'CI + SonarQube Quality Gate PASSED.'
        }

        failure {
            echo 'Pipeline FAILED. Check lint, tests, SonarQube analysis, or Quality Gate.'
        }

        always {
            archiveArtifacts(
                artifacts: 'ci-artifacts/**',
                fingerprint: true,
                allowEmptyArchive: true
            )

            sh '''
                docker image rm \
                    "${IMAGE_NAME}:ci-${BUILD_NUMBER}" \
                    >/dev/null 2>&1 || true
            '''
        }
    }
}