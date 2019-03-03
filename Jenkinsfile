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
    MINT_PATH = "/opt/mint/lib"
  }
  stages {
    stage('Bootstrap') {
      steps {
        sh 'make bootstrap'
      }
    }
    stage('Generate Project') {
      steps {
        sh 'make project'
      }
    }
    stage('Test') {
      steps {
        sh 'make test'
      }
    }
  }
}
