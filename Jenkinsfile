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
        AWS_REGION = 'ap-south-1'
        AWS_DEFAULT_REGION = 'ap-south-1'

        SSM_DOCKERHUB_USERNAME = '/cloud-devops-lab/jenkins/dockerhub/username'

        SSM_DOCKERHUB_TOKEN = '/cloud-devops-lab/jenkins/dockerhub/token'

        SSM_DEPLOY_SSH_KEY = '/cloud-devops-lab/jenkins/deploy/ssh_private_key'

        SSM_SONAR_TOKEN = '/cloud-devops-lab/jenkins/sonar/token'
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
                    set +x
                    set -e

                    SONAR_TOKEN=\$(
                        aws ssm get-parameter \
                            --name "\$SSM_SONAR_TOKEN" \
                            --with-decryption \
                            --query Parameter.Value \
                            --output text
                    )

                    test -n "\$SONAR_TOKEN"

                    ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.token="\$SONAR_TOKEN"

                    unset SONAR_TOKEN
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

        stage('Resolve Deployment Metadata') {
            steps {
                script {
                    env.DOCKERHUB_USER = sh(
                script: '''
                    aws ssm get-parameter \
                        --name "$SSM_DOCKERHUB_USERNAME" \
                        --query Parameter.Value \
                        --output text
                ''',
                returnStdout: true
            ).trim()

                    env.DEPLOY_IMAGE =
                "${env.DOCKERHUB_USER}/cloud-devops-lab-app:${env.IMAGE_TAG}"

                    env.LATEST_IMAGE =
                "${env.DOCKERHUB_USER}/cloud-devops-lab-app:latest"
                }

                sh '''
            echo "Deployment image:"
            echo "$DEPLOY_IMAGE"
        '''
            }
        }

        stage('Publish Docker Image') {
            steps {
                sh '''
            set +x
            set -eu

            DOCKERHUB_TOKEN=$(
                aws ssm get-parameter \
                    --name "$SSM_DOCKERHUB_TOKEN" \
                    --with-decryption \
                    --query Parameter.Value \
                    --output text
            )

            test -n "$DOCKERHUB_TOKEN"

            cleanup_docker_auth() {
                docker logout >/dev/null 2>&1 || true
                unset DOCKERHUB_TOKEN
            }

            trap cleanup_docker_auth EXIT

            printf '%s' "$DOCKERHUB_TOKEN" |
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

        stage('Deploy to Private App EC2') {
            steps {
                sh '''
            set +x
            set -eu

            KEY_FILE=$(mktemp)

            cleanup_key() {
                chmod 600 "$KEY_FILE" 2>/dev/null || true

                if command -v shred >/dev/null 2>&1; then
                    shred -u "$KEY_FILE" 2>/dev/null || rm -f "$KEY_FILE"
                else
                    rm -f "$KEY_FILE"
                fi
            }

            trap cleanup_key EXIT

            aws ssm get-parameter \
                --name "$SSM_DEPLOY_SSH_KEY" \
                --with-decryption \
                --query Parameter.Value \
                --output text \
                > "$KEY_FILE"

            chmod 600 "$KEY_FILE"

            cd ansible

            echo "Checking private application server..."

            ansible "$APP_INVENTORY_GROUP" \
                -m ping \
                --private-key "$KEY_FILE"

            echo "Deploying:"
            echo "$DEPLOY_IMAGE"

            ansible-playbook \
                playbooks/deploy-app.yml \
                --limit "$APP_INVENTORY_GROUP" \
                --private-key "$KEY_FILE" \
                -e "app_image=$DEPLOY_IMAGE"
        '''
            }
        }

        stage('Verify AWS Identity') {
            steps {
                sh '''
            set -eu

            echo "Verifying Jenkins EC2 IAM identity..."

            aws sts get-caller-identity \
                --query Arn \
                --output text

            echo "Verifying approved SSM parameter access..."

            aws ssm get-parameter \
                --name "$SSM_DOCKERHUB_USERNAME" \
                --query Parameter.Name \
                --output text
        '''
            }
        }
    }
    post {
        success {
            echo 'CI/CD pipeline PASSED.'
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
