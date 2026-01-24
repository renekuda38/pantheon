pipeline {
    agent {
        label 'docker'
    }

    environment {
        // add uv to PATH, later will be integrated in Dockerfile together with uv installation
        PATH = "/var/jenkins_home/.local/bin:${env.PATH}"

        DOCKER_IMAGE_API = "python-taskmaster-api"
        DOCKER_IMAGE_DB = "postgres-taskmaster-db" 
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
                        def customImage = docker.build("${DOCKER_IMAGE_API}:${DOCKER_TAG}", "-f Dockerfile.api .")
                        customImage.tag('latest')

                        def dbImage = docker.build("${DOCKER_IMAGE_DB}:${DOCKER_TAG}", "-f Dockerfile.db .")
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
                        withCredentials([string(credentialsId: 'postgres-password', variable: 'DB_PASS')]) {
                            sh '''                                                                                                                                                                                                                 
                                docker compose down || true                                                                                                                                                                                        
                                docker compose rm -f || true                                                                                                                                                                                       
                                                                                                                                                                                                                                                    
                                export POSTGRES_USER=taskmaster                                                                                                                                                                                    
                                export POSTGRES_PASSWORD="\${DB_PASS}"                                                                                                                                                                              
                                export POSTGRES_DB=taskmaster_db                                                                                                                                                                                   
                                export DATABASE_URL="postgresql://taskmaster:\${DB_PASS}@db:5432/taskmaster_db"
                                export IMAGE_TAG=${BUILD_NUMBER}                                                                                                                                     
                                                                                                                                                                                                                                                    
                                docker compose up -d                                                                                                                                                                                               
                                docker compose ps                                                                                                                                                                                                  
                            '''     
                        }        
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
                    
                    sh 'docker network connect pantheon-network jenkins-agent-docker01 || true'

                    dir('scripts') {
                        // Check FastAPI liveness
                        echo 'Checking FastAPI liveness...'
                        sh '''
                            chmod +x healthcheck_fastapi.sh
                            ./healthcheck_fastapi.sh http://taskmaster-api:8000/health
                        '''
                        echo 'FastAPI process is running'
                        
                        // Check database readiness
                        echo 'Checking database connection...'
                        sh '''
                            ./healthcheck_fastapi.sh http://taskmaster-api:8000/db-health
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
            echo "✓ API Image: ${DOCKER_IMAGE_API}:${DOCKER_TAG}"
            echo "✓ DB Image: ${DOCKER_IMAGE_DB}:${DOCKER_TAG}"
            echo "✓ Health: All checks passed"
            echo "✓ Access: http://host.docker.internal:8000"
            echo "✓ Docs: http://host.docker.internal:8000/docs"
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