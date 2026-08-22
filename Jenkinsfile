pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    triggers {
        pollSCM('H/2 * * * *')
    }

    parameters {
        booleanParam(
            name: 'FORCE_TEST_FAILURE',
            defaultValue: false,
            description: 'Intentional unit-test failure drill'
        )
    }

    environment {
        APP_DIR = 'app'
        IMAGE_NAME = 'cloud-devops-lab-app'
        APP_INVENTORY_GROUP = 'app'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.SHORT_SHA = sh(
                        script: 'git rev-parse --short=7 HEAD',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG =
                        "${env.BUILD_NUMBER}-${env.SHORT_SHA}"
                }

                sh '''
                    echo "Commit:"
                    git rev-parse --short HEAD

                    echo "Image tag:"
                    echo "$IMAGE_TAG"
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
                    ansible --version
                    ssh -V
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
                            'Intentional CI failure requested'
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
                        --label ci.build="$BUILD_NUMBER" \
                        --label ci.commit="$SHORT_SHA" \
                        -t "$IMAGE_NAME:ci-$BUILD_NUMBER" \
                        "$APP_DIR"

                    mkdir -p ci-artifacts

                    docker image inspect \
                        "$IMAGE_NAME:ci-$BUILD_NUMBER" \
                        > ci-artifacts/docker-image.json
                '''
            }
        }

        stage('Publish Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    script {
                        env.DEPLOY_IMAGE =
                            "${env.DOCKERHUB_USER}/cloud-devops-lab-app:${env.IMAGE_TAG}"

                        env.LATEST_IMAGE =
                            "${env.DOCKERHUB_USER}/cloud-devops-lab-app:latest"
                    }

                    sh '''
                        set +x

                        trap 'docker logout >/dev/null 2>&1 || true' EXIT

                        echo "$DOCKERHUB_TOKEN" |
                            docker login \
                                --username "$DOCKERHUB_USER" \
                                --password-stdin

                        docker tag \
                            "$IMAGE_NAME:ci-$BUILD_NUMBER" \
                            "$DEPLOY_IMAGE"

                        docker tag \
                            "$IMAGE_NAME:ci-$BUILD_NUMBER" \
                            "$LATEST_IMAGE"

                        docker push "$DEPLOY_IMAGE"
                        docker push "$LATEST_IMAGE"

                        echo "Published image:"
                        echo "$DEPLOY_IMAGE"
                    '''
                }
            }
        }

    stage('Deploy to Private App EC2') {
        steps {
            withCredentials([
            sshUserPrivateKey(
            credentialsId: 'app-deploy-ssh',
            keyFileVariable: 'ANSIBLE_KEY'
        )
        ]) {
            sh '''
                cd ansible

                echo "Checking Ansible target..."
                ansible "$APP_INVENTORY_GROUP" \
                    -m ping \
                    --private-key "$ANSIBLE_KEY"

                echo "Deploying image:"
                echo "$DEPLOY_IMAGE"

                ansible-playbook \
                    playbooks/deploy-app.yml \
                    --limit "$APP_INVENTORY_GROUP" \
                    --private-key "$ANSIBLE_KEY" \
                    -e "app_image=$DEPLOY_IMAGE"'''
                }
            }
        }

    post {

        success {
            echo "CI/CD pipeline PASSED."
            echo "Deployed image: ${env.DEPLOY_IMAGE}"
        }

        failure {
            echo 'Pipeline FAILED. Check the failed stage.'
        }

        always {
            archiveArtifacts(
                artifacts: 'ci-artifacts/**',
                fingerprint: true,
                allowEmptyArchive: true
            )

            sh '''
                docker image rm \
                    "$IMAGE_NAME:ci-$BUILD_NUMBER" \
                    >/dev/null 2>&1 || true

                if [ -n "${DEPLOY_IMAGE:-}" ]; then
                    docker image rm \
                        "$DEPLOY_IMAGE" \
                        >/dev/null 2>&1 || true
                fi

                if [ -n "${LATEST_IMAGE:-}" ]; then
                    docker image rm \
                        "$LATEST_IMAGE" \
                        >/dev/null 2>&1 || true
                fi
            '''
        }
    }
}