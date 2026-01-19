pipeline {
    agent {
        label 'docker'
    }

    environment {
        // add uv to PATH, later will be integrated in Dockerfile together with uv installation
        PATH = "/var/jenkins_home/.local/bin:${env.PATH}"

        DOCKER_IMAGE = "taskmaster_api"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }  
    

    stages {
        stage('Checkout') {
            steps {
                echo '... checking out source code ...'

                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo '... installing Python dependencies with uv ...'

                dir('backend') {
                    sh '''
                        #!/usr/bin/env bash

                        set -euo pipefail
                        
                        which uv || (echo "uv not found!" && exit 1)

                        uv venv .venv

                        . .venv/bin/activate

                        uv pip install -e ".[dev]"

                        uv pip list

                        echo 
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                echo '... running tests ...'

                dir('backend') {
                    sh '''
                        set -euo pipefail

                        . .venv/bin/activate

                        # testy pridame neskor 

                        echo '... testing imports ...'
                        python -c "from taskmaster_api import app; print('app imports successfully')"

                        echo '... syntax validation for all python files ...'
                        find taskmaster_api -name "*.py" -exec python -m py_compile {} +
                        
                        echo "all python files are syntactically correct"
                    '''
                }
            }
        }        

        stage('Build Docker Image') {
            steps {
                echo '... building docker image ...'

                dir('backend') {
                    script {
                        def customImage = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                        customImage.tag('latest')
                    }
                }
            }
        }
    }

    post {
        always {
            echo '... cleaning up the workspace ...'
            cleanWs()
        }
        success {
            echo """
                    ╔════════════════════════════════════════╗
                    ║          BUILD INFORMATION             ║
                    ╠════════════════════════════════════════╣
                    ║ Project: ${env.JOB_NAME}
                    ║ Build:   #${env.BUILD_NUMBER}
                    ║ Branch:  ${env.BRANCH_NAME}
                    ║ Commit:  ${env.GIT_COMMIT.take(7)}
                    ║ Author:  ${env.GIT_COMMITTER_NAME}
                    ╚════════════════════════════════════════╝
            """
        }
        failure {
            echo 'PIPELINE FAILED! check logs above.'
        }
    }
}
