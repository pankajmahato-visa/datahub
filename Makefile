TAG ?= $(eval TAG := $(shell git describe --tags --always --dirty)-$(shell git diff | sha256sum | cut -c -6))$(TAG)
TAG_VERSION=$(subst -e3b0c4,,$(TAG))
TAR_BALL_VERSION="datahub-"$(subst -,.,$(TAG_VERSION))
.PHONY: init clean build test datahub-upgrade-test metadata-service-test datahub-frontend-test package

init:
	echo "TAG:" ${TAG}; \
	echo "TAG_VERSION:" ${TAG_VERSION}; \
	echo "TAR_BALL_VERSION:" ${TAR_BALL_VERSION}; \
	echo "Setting Gradle Wrapper Credentials for gradle download"; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	echo "Java Version"; \
	java -version; \
	echo "NPM Version"; \
	npm -v; \
	echo "Node Version"; \
	node -v; \
	echo "Yarn Version"; \
	yarn -v; \
	echo "Gradle Version"; \
	./gradlew -v

clean:
	echo "Setting Gradle Wrapper Credentials for gradle download"; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	echo "Running Datahub Frontend Clean Task"; \
	./gradlew --scan --info :datahub-frontend:clean; \
	echo "Running Metadata Service WAR Clean Task"; \
	./gradlew --scan --info :metadata-service:war:clean; \
	echo "Running Datahub Upgrade Clean Task"; \
	./gradlew --scan --info :datahub-upgrade:clean

build:
	echo "Setting Gradle Wrapper Credentials for gradle download"; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	echo "Running Metadata Service WAR build Task"; \
	./gradlew --scan --info :metadata-service:war:build; \
	echo "Running Datahub Upgrade build Task"; \
	./gradlew --scan --info :datahub-upgrade:build; \
	echo "Running Datahub Frontend build Task"; \
	./gradlew --scan --info :datahub-frontend:build

test: datahub-upgrade-test metadata-service-test datahub-frontend-test

datahub-upgrade-test:
	echo "Setting Gradle Wrapper Credentials for gradle download"; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	echo "Running Datahub Upgrade Test Task"; \
	./gradlew --scan --info --scan :datahub-upgrade:test

metadata-service-test: init
	echo "Setting Gradle Wrapper Credentials for gradle download"; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	echo "Running Metadata Service sub-modules & WAR Test Task"; \
	./gradlew --scan --info :metadata-service:auth-config:test; \
	./gradlew --scan --info :metadata-service:auth-filter:test; \
	./gradlew --scan --info :metadata-service:auth-impl:test; \
	./gradlew --scan --info :metadata-service:auth-servlet-impl:test; \
	./gradlew --scan --info :metadata-service:factories:test; \
	./gradlew --scan --info :metadata-service:graphql-servlet-impl:test; \
	./gradlew --scan --info :metadata-service:openapi-servlet:test; \
	./gradlew --scan --info :metadata-service:plugin:test; \
	./gradlew --scan --info :metadata-service:plugin:src:test; \
	./gradlew --scan --info :metadata-service:plugin:src:test:test; \
	./gradlew --scan --info :metadata-service:plugin:src:test:sample-test-plugins:test; \
	./gradlew --scan --info :metadata-service:restli-api:test; \
	./gradlew --scan --info :metadata-service:restli-client:test; \
	./gradlew --scan --info :metadata-service:restli-servlet-impl:test; \
	./gradlew --scan --info :metadata-service:servlet:test; \
	./gradlew --scan --info :metadata-service:war:test

datahub-frontend-test:
	echo "Setting Gradle Wrapper Credentials for gradle download"; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	echo "Running Datahub Upgrade Test Task"; \
	./gradlew --scan --info --scan --info :datahub-frontend:test

package:
	echo "Setting Gradle Wrapper Credentials for gradle download"; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	export LANG=en_US.UTF-8; \
    export LC_ALL=$LANG; \
    export LANGUAGE=$LANG; \
	echo "Packaging Datahub Artifacts to folder: datahub-artifact"; \
	mkdir datahub-artifact; \
	mkdir datahub-artifact/datahub-gms; \
	mkdir datahub-artifact/datahub-frontend; \
	mkdir datahub-artifact/datahub-upgrade; \
	mkdir datahub-artifact/lib; \
	mkdir datahub-artifact/certs; \
	mkdir datahub-artifact/setup; \
	mkdir datahub-artifact/setup/elasticsearch-setup; \
	mkdir datahub-artifact/setup/kafka-setup; \
	mkdir datahub-artifact/setup/mysql-setup; \
	mkdir datahub-artifact/resources; \
	echo "Current datahub-artifact folder tree"; \
	find datahub-artifact | sort | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"; \
	echo "1. Copying Datahub Frontend Tar ball"; \
	cp datahub-frontend/build/distributions/datahub-frontend-*.tar datahub-artifact; \
	echo "2. Copying Datahub Upgrade JAR"; \
	cp datahub-upgrade/build/libs/datahub-upgrade.jar datahub-artifact; \
	echo "3. Copying Metadata Service WAR"; \
	cp metadata-service/war/build/libs/war.war datahub-artifact; \
	echo "4. Copying Elastic Setup"; \
	cp docker/elasticsearch-setup/create-indices.sh datahub-artifact/setup/elasticsearch-setup/create-indices.sh; \
	echo "5. Copying Kafka Setup"; \
	cp docker/kafka-setup/{kafka-config.sh,kafka-setup.sh,kafka-topic-workers.sh} datahub-artifact/setup/kafka-setup; \
	echo "6. Copying MySQL Setup"; \
	cp docker/mysql-setup/{init.sh,init.sql} datahub-artifact/setup/mysql-setup; \
	echo "7. Copying entity-registry.yml"; \
	cp metadata-models/src/main/resources/entity-registry.yml datahub-artifact/resources; \
	echo "8. Downloading jetty files"; \
	chmod u+x download.sh; \
	./download.sh; \
	echo "9. Downloading VISA Certificates"; \
	echo "10. Copying Datahub GMS files"; \
	cp docker/datahub-gms/{start.sh,jetty.xml} datahub-artifact/datahub-gms; \
	echo "11. Copying Datahub Frontend files"; \
    cp docker/datahub-frontend/start.sh datahub-artifact/datahub-frontend; \
	cp metadata-service/war/build/libs/war.war datahub-artifact; \
	echo "Final datahub-artifact folder tree"; \
	find datahub-artifact | sort | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"; \
	tar cvf ${TAR_BALL_VERSION}.tar datahub-artifact; \
	ls -lah ${TAR_BALL_VERSION}.tar

