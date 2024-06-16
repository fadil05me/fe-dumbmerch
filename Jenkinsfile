pipeline {
    agent any
    
    environment {
        BUILD_SERVER = 'finaltask-fadil@52.187.151.49'
        DEPLOY_SERVER = 'finaltask-fadil@103.127.134.73'
        DIRECTORY = '/home/finaltask-fadil/build/staging/frontend'
        BRANCH = 'staging'
        REPO_URL = 'git@github.com:fadil05me/fe-dumbmerch.git'
        SSH_PORT = '1234'
        REGISTRY_URL = 'registry.fadil.studentdumbways.my.id'
        IMAGE_NAME = 'fe-dumbmerch-staging'
    }
    
    stages {
        stage('Clean up stage') {
            steps {
                script {
                    sshagent(credentials: ['sshkey']) {
                        // Clean up directory and Docker images
                        sh """
                        ssh -p ${SSH_PORT} -o StrictHostKeyChecking=no ${BUILD_SERVER} << 'EOF'
                        rm -rf ${DIRECTORY}
                        mkdir -p ${DIRECTORY}
                        echo "Directory cleaned and recreated!"

                        docker rmi -f \$(docker images ${REGISTRY_URL}/${IMAGE_NAME} -q)
                        echo "All images deleted!"

                        exit
                        EOF
                        """
                    }
                }
            }
        }
        
        stage('Pull Code and Build') {
            steps {
                script {
                    sshagent(credentials: ['sshkey']) {
                        // Clone repository and read version from file
                        sh """
                        ssh -p ${SSH_PORT} -o StrictHostKeyChecking=no ${BUILD_SERVER} << 'EOF'
                        cd ${DIRECTORY}
                        git clone -b ${BRANCH} ${REPO_URL} .
                        echo "Selesai Pulling! Branch: ${BRANCH}"
                        
                        # Read version from file
                        version=\$(cat ${DIRECTORY}/version)
                        echo "Using version: \${version}"
                        
                        # Build Docker image with the retrieved version
                        docker build -t "${REGISTRY_URL}/${IMAGE_NAME}:\${version}" .
                        echo "Docker image built with tag: \${version}"
                        
                        exit
                        EOF
                        """
                    }
                }
            }
        }
        
        stage('Start docker container') {
            steps {
                script {
                    sshagent(credentials: ['sshkey']) {
                        // Read version from file and run Docker container
                        sh """
                        ssh -p ${BUILD_SERVER} -o StrictHostKeyChecking=no ${BUILD_SERVER} << 'EOF'
                        cd ${DIRECTORY}
                        
                        # Read version from file
                        version=\$(cat ${DIRECTORY}/version)
                        echo "Using version: \${version}"
                        
                        # Run Docker container using the retrieved version
                        docker run -d --name testcode -p 3000:80 "${REGISTRY_URL}/${IMAGE_NAME}:\${version}"
                        echo "Docker container started with image tag: \${version}"
                        
                        exit
                        EOF
                        """
                    }
                }
            }
        }

        stage('Checking website using wget spider') {
            steps {
                script {
                    sshagent(credentials: ['sshkey']) {
                        sh """
                            ssh -p ${BUILD_SERVER} -o StrictHostKeyChecking=no ${BUILD_SERVER} << 'EOF'
                            if wget --spider http://localhost:3000 >/dev/null 2>&1; then
                                echo "Website is up!"
                            else
                                echo "Website is down!"
                                docker rm -f testcode
                                exit 1
                            fi
                            docker rm -f testcode
                            echo "Selesai Testing!"
                            exit
                            EOF
                            """
                    }
                }
            }
        }

        stage('Pushing image to private registry') {
            steps {
                script {
                    sshagent(credentials: ['sshkey']) {
                        sh """
                            ssh -p 1234 -o StrictHostKeyChecking=no finaltask-fadil@40.118.209.246 << 'EOF'
                            cd ${DIRECTORY}
                            
                            # Read version from file
                            version=\$(cat ${DIRECTORY}/version)
                            echo "Using version: \${version}"

                            # Add tag latest
                            docker tag "${REGISTRY_URL}/${IMAGE_NAME}:\${version}" "${REGISTRY_URL}/${IMAGE_NAME}:latest"

                            # Push new version and latest
                            docker push "${REGISTRY_URL}/${IMAGE_NAME}:\${version}"
                            docker push "${REGISTRY_URL}/${IMAGE_NAME}:latest"
                            exit
                            EOF
                            """
                    }
                }
            }
        }

        stage('Deploy docker container') {
            steps {
                script {
                    sshagent(credentials: ['sshkey']) {
                        // Read version from file and run Docker container
                        sh """
                        ssh -p ${SSH_PORT} -o StrictHostKeyChecking=no ${DEPLOY_SERVER} << 'EOF'
                        cd ${DIRECTORY}
                        
                        # Stop docker container
                        docker stop frontend
                        docker rm -f frontend

                        # Run Docker container using the latest version
                        docker run --pull always -d --name frontend -p 3000:80 "${REGISTRY_URL}/${IMAGE_NAME}:latest"
                        echo "Docker container started with image tag: latest"
                        
                        exit
                        EOF
                        """
                    }
                }
            }
        }

    }

}
