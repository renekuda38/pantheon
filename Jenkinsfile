pipeline {
    agent any

    environment {
        PATH = "/var/jenkins_home/.local/bin:${env.PATH}"

        DOCKER_IMAGE = "taskmaster_api"
        DOCKER_TAG = "${env.BUILD_NUMBER}"

        UV_VERSION = "latest"
    }  
    
    stages {
        stage('Checkout') {
            steps {
                echo 'checking out source code ...'
                checkout scm
                
                sh '''
                    echo "Git commit: $(git rev-parse HEAD)"
                    echo "Git branch: $(git rev-parse --abbrev-ref HEAD)"
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'installing Python dependencies with uv ...'

                dir('backend') {
                    sh '''
                        which uv || (echo "uv not found!" && exit 1)

                        uv venv .venv

                        . .venv/bin/activate

                        uv pip install -e .

                        uv pip list
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                echo 'running tests ...'

                dir('backend') {
                    sh '''
                        . .venv/bin/activate

                        # testy pridame neskor 

                        echo 'testing imports ...'
                        python -c "from taskmaster_api import app; print('app imports successfully')"

                        echo 'syntax validation for all python files ...'
                        find taskmaster_api -name "*.py" -exec python -m py_compile {} +
                        
                        echo "all python files are syntactically correct"
                    '''
                }
            }
        }        

        stage('Build Docker Image') {
            steps {
                echo 'building docker image ...'

                script {
                    dir('backend') {
                        def customImage = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")

                        customImage.tag('latest')

                        echo "built image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'cleaning up the workspace ...'
            cleanWs()
        }
        success {
            echo 'pipeline completed successfully'
            echo "docker image ready: ${DOCKER_IMAGE}:${DOCKER_TAG}"
        }
        failure {
            echo 'pipeline failed! check logs above.'
        }
    }
}
