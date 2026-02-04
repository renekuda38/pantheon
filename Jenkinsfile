pipeline {
    agent {
        label 'docker'
    }

    environment {
        // add uv to PATH, later will be integrated in Dockerfile together with uv installation
        PATH = "/var/jenkins_home/.local/bin:${env.PATH}"

        DOCKER_IMAGE_API = "python-taskmaster-api"
        DOCKER_IMAGE_DB = "postgres-taskmaster-db" 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
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
                        def customImage = docker.build("${DOCKER_IMAGE_API}:${IMAGE_TAG}", "-f Dockerfile.api .")
                        customImage.tag('latest')

                        def dbImage = docker.build("${DOCKER_IMAGE_DB}:${IMAGE_TAG}", "-f Dockerfile.db .")
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

                                # # # env vars for db service                                                                                                                                                                                                      
                                export POSTGRES_USER=taskmaster                                                                                                                                                                                    
                                export POSTGRES_PASSWORD="\${DB_PASS}"                                                                                                                                                                              
                                export POSTGRES_DB=taskmaster_db      

                                # # # env vars for api service   
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
                    
                    // find out the name of the Jenkins agent container
                    def agentContainerName = sh(
                        script: "cat /etc/hostname",
                        returnStdout: true
                    ).trim()

                    sh "docker network connect app-network ${agentContainerName} || true"

                    try {
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
                    } finally {
                        // Disconnect the Jenkins agent container from the app network
                        sh "docker network disconnect app-network ${agentContainerName} || true"
                    }

                    sh "docker network disconnect app-network ${agentContainerName} || true"
                    
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
            echo "✓ API Image: ${DOCKER_IMAGE_API}:${IMAGE_TAG}"
            echo "✓ DB Image: ${DOCKER_IMAGE_DB}:${IMAGE_TAG}"
            echo "✓ Health: All checks passed"
            echo "✓ Access: http://taskmaster-api:8000"
        }
        
        failure {
            echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
            echo '  ❌ PIPELINE FAILED'
            echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
            
            dir('backend') {
                echo 'Recent container logs:'
                sh 'docker compose logs --tail=100 || true'
            }
        }
        
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
    }
}