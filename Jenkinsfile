// If referencing variables inside functions, don't use 'def' keyword
// https://stackoverflow.com/a/47007544/2695864
docker_image = "koha-community"
docker_version = "latest"

pipeline {
    agent any

    environment {
        _DOCKER_REGISTRY_CREDENTIALS = credentials('jenkins.bot_username_password')
    }

    stages {
        stage('Build app tag latest') {
            steps {
                docker_registry_login()
                build_app(docker_version)
            }
        }
        stage('Build app tag commit') {
            when {
                allOf {
                    expression { gitlabAfter != null }
                }
            }
            steps {
                docker_registry_login()
                build_app(gitlabAfter)
            }
        }
    }
}

def docker_registry_login() {
    sh "bash -c 'echo ${_DOCKER_REGISTRY_CREDENTIALS_PSW} | docker login ${_DOCKER_REGISTRY} --username ${_DOCKER_REGISTRY_CREDENTIALS_USR} --password-stdin'"
}

def build_app(version) {
    sh "bash -c './build.sh --registry ${_DOCKER_REGISTRY} --image ${docker_image} --version ${version}'"
}
