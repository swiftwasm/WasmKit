pipeline {
  agent {
    node {
      label 'mac'
    }
  }
  environment {
    CI = 'jenkins'
    LANG = 'en_US.UTF-8'
    PATH = "/usr/local/bin:$PATH"
  }
  stages {
    stage('Bootstrap') {
      steps {
        sh 'brew install swiftlint'
      }
    }
    stage('Lint') {
      steps {
        sh 'swiftlint --strict'
      }
    }
    stage('Test') {
      steps {
        sh 'make test'
      }
    }
  }
}
