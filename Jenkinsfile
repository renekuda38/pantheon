pipeline {
    agent {
        label 'docker'
    }

    environment {
        // add uv to PATH, later will be integrated in Dockerfile together with uv installation
        PATH = "/var/jenkins_home/.local/bin:${env.PATH}"

        DOCKER_IMAGE_API = "taskmaster_api"
        DOCKER_IMAGE_DB = "taskmaster-db" 
        DOCKER_TAG = "${env.BUILD_NUMBER}"

        POSTGRES_PASSWORD = credentials('postgres-password')
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
                        def customImage = docker.build("${DOCKER_IMAGE_API}:${DOCKER_TAG}")
                        customImage.tag('latest')

                        def dbImage = docker.build("${DOCKER_IMAGE_DB}:${DOCKER_TAG}", "-f Dockerfile.postgres .")
                        dbImage.tag('latest')
                    }
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                    echo '  🚀 DEPLOYING APPLICATION'
                    echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                    
                    dir('backend') {

                        sh '''
                            cat > .env << EOF
                            POSTGRES_USER=taskmaster
                            POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
                            POSTGRES_DB=taskmaster_db
                            DATABASE_URL=postgresql://taskmaster:${POSTGRES_PASSWORD}@db:5432/taskmaster_db
                            EOF
                        '''
                        // Stop existing deployment
                        sh 'docker compose down || true'
                        
                        // Remove old containers
                        sh 'docker compose rm -f || true'
                        
                        // Start all services
                        sh 'docker compose up -d'
                        
                        // Show status
                        echo 'Container status:'
                        sh 'docker compose ps'
                    }
                    
                    echo '✓ Deployment completed'
                }
            }
        }
        
        stage('Healthcheck') {
            steps {
                script {
                    echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                    echo '  🏥 HEALTH CHECK VERIFICATION'
                    echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                    
                    // Wait for containers to fully start
                    echo 'Waiting for services to initialize...'
                    sleep(time: 15, unit: 'SECONDS')
                    

                    dir('scripts') {
                        // Check FastAPI liveness
                        echo 'Checking FastAPI liveness...'
                        sh '''
                            chmod +x healthcheck_fastapi.sh
                            ./healthcheck_fastapi.sh http://localhost:8000/health
                        '''
                        echo 'FastAPI process is running'
                        
                        // Check database readiness
                        echo 'Checking database connection...'
                        sh '''
                            ./healthcheck_fastapi.sh http://localhost:8000/db-health
                        '''
                        echo 'Database connection verified'
                    }
                    
                    echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                    echo '  ✅ ALL HEALTH CHECKS PASSED'
                    echo '  • FastAPI: ✓ Running'
                    echo '  • Database: ✓ Connected'
                    echo '  • Status: Ready for traffic'
                    echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                }
            }
        }
    }
    
    post {
        success {
            echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
            echo '  🎉 PIPELINE COMPLETED SUCCESSFULLY'
            echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
            echo "✓ Build: ${env.BUILD_NUMBER}"
            echo "✓ Image: ${DOCKER_IMAGE}:${IMAGE_TAG}"
            echo "✓ Health: All checks passed"
            echo "✓ Access: http://localhost:8000"
            echo "✓ Docs: http://localhost:8000/docs"
        }
        
        failure {
            echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
            echo '  ❌ PIPELINE FAILED'
            echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
            
            dir('backend') {
                echo 'Recent container logs:'
                sh 'docker-compose logs --tail=100 || true'
            }
        }
        
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
    }
}