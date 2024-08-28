pipeline {
    agent {
        node {
            label params.SLAVE
        }
    }

    parameters {
        string(name: 'SD_VERSION', defaultValue: '')
    }

    environment {
        GIT_CMD = "docker run --rm -v ${env.WORKSPACE}:/git alpine/git"
        BASELINE_CHART_REPO_URL = "https://arm.epk.ericsson.se/artifactory/proj-orchestration-sd-helm/"
    }

    stages {
        stage('[clean]') {
        	when {
                expression { params.RELEASE == "true" }
            }
            steps {
                sh '${GIT_CMD} clean -xdff'
            }
        }

        stage('Build Package') {
        	when {
                expression { params.RELEASE == "true" }
            }
            steps {
                sh 'chmod +x build/so-create-csar.bash'
                sh 'build/so-create-csar.bash'
            }
        }

        stage('Publish Package to Nexus') {
        	when {
                expression { params.RELEASE == "true" }
            }
            steps {
	    	nexusPublisher nexusInstanceId: 'arm101-eiffel052', nexusRepositoryId: 'eo-releases', packages: [[$class: 'MavenPackage', mavenAssetList: [[classifier: '', extension: '', filePath: "/home/lciadm100/jenkins/workspace/sd-baseline-packaging_Release/sd-${params.SD_VERSION}.csar"]], mavenCoordinate: [artifactId: 'sd-package', groupId: 'com.ericsson.so', packaging: 'csar', version: "${params.SD_VERSION}"]]]
	    }
        }
        stage('[clean after build]') {
            when {
                expression { params.RELEASE == "true" && params.SD_VERSION != "" }
            }
            steps {
                sh '${GIT_CMD} clean -xdff'
            }
        }
    }
}
