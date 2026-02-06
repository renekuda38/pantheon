pipeline {
    agent {
        label 'docker'
    }

    environment {
        // add uv to PATH, later will be integrated in Dockerfile together with uv installation
        PATH = "/var/jenkins_home/.local/bin:${env.PATH}"
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
        
        stage('Deploy') {
            steps {
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                echo '  🚀 DEPLOYING APPLICATION'
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                
                dir('ansible') {
                    sh 'ansible-playbook -i inventory.ini deploy.yml'     
                }   
                echo '✓ Deployment completed'
            }
        }
        
        stage('Healthcheck') {
            steps {
                echo 'Waiting for services to initialize...'
                sleep(time: 15, unit: 'SECONDS')

                sh 'curl -f http://host.docker.internal:8000/health'
                sh 'curl -f http://host.docker.internal:8000/db-health'
            }
        }
    }
    
    post {
        success {
            echo "✓ Access: http://localhost:8000"
        }
        
        failure {
            echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
            echo '  ❌ PIPELINE FAILED'
            echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
            
            sh 'sshpass -p deploy -o StrictHostKeyChecking=no \
                -p 2222 deploy@host.docker.internal \
                "cd /opt/app/backend && docker compose logs --tail=100" || true'
        }
        
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
    }
}