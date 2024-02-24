TAG ?= $(eval TAG := $(shell git describe --tags --always --dirty)-$(shell git diff | sha256sum | cut -c -6))$(TAG)
TAG_VERSION=$(subst -e3b0c4,,$(TAG))
TAR_BALL_VERSION="datahub-"$(subst -,.,$(TAG_VERSION))
.PHONY: init test clean build package

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
	echo "Running Complete Datahub Clean Task"; \
	./gradlew --stacktrace clean

#test:
#	echo "Setting Gradle Wrapper Credentials for gradle download"; \
#	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
#	echo "Running Test for all modules"; \
#	./gradlew --stacktrace test \
#	-x :datahub-frontend:build \
#	-x :datahub-frontend:cleanLocalDockerImages \
#	-x :datahub-frontend:dist \
#	-x :datahub-frontend:myTar \
#	-x :datahub-frontend:test \
#	-x :datahub-frontend:unversionZip \
#	-x :datahub-graphql-core:test \
#	-x :datahub-web-react:build \
#	-x :datahub-web-react:copyAssets \
#	-x :datahub-web-react:distZip \
#	-x :datahub-web-react:jar \
#	-x :datahub-web-react:test \
#	-x :datahub-web-react:yarnQuickBuild \
#	-x :datahub-web-react:yarnTest \
#	-x :entity-registry:test \
#	-x :ingestion-scheduler:test \
#	-x :metadata-ingestion-modules:airflow-plugin:build \
#	-x :metadata-ingestion-modules:airflow-plugin:check \
#	-x :metadata-ingestion:build \
#	-x :metadata-ingestion:check \
#	-x :metadata-integration:java:datahub-client:checkShadowJar \
#	-x :metadata-integration:java:datahub-client:test \
#	-x :metadata-integration:java:spark-lineage:compileJava \
#	-x :metadata-integration:java:spark-lineage:compileTestJava \
#	-x :metadata-integration:java:spark-lineage:test \
#	-x :metadata-io:test \
#	-x :metadata-jobs:mae-consumer:test \
#	-x :metadata-service:auth-impl:test \
#	-x :metadata-service:factories:test \
#	-x :metadata-service:openapi-entity-servlet:test \
#	-x :metadata-service:plugin:test \
#	-x :metadata-service:schema-registry-servlet:test \
#	-x :metadata-utils:test \
#	-x docs-website:build \
#	--parallel --continue

test:
	echo "Setting Gradle Wrapper Credentials for gradle download"; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	echo "Running Test for all modules"; \
	./gradlew :metadata-service:war:test; \
	./gradlew :datahub-frontend:test; \
	./gradlew :datahub-upgrade:test;

#build:
#	echo "Setting Gradle Wrapper Credentials for gradle download"; \
#	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
#	echo "Running Build and Test for all modules"; \
#	./gradlew --stacktrace build \
#	-x :datahub-frontend:build \
#	-x :datahub-frontend:cleanLocalDockerImages \
#	-x :datahub-frontend:dist \
#	-x :datahub-frontend:myTar \
#	-x :datahub-frontend:test \
#	-x :datahub-frontend:unversionZip \
#	-x :datahub-graphql-core:test \
#	-x :datahub-web-react:build \
#	-x :datahub-web-react:copyAssets \
#	-x :datahub-web-react:distZip \
#	-x :datahub-web-react:jar \
#	-x :datahub-web-react:test \
#	-x :datahub-web-react:yarnQuickBuild \
#	-x :datahub-web-react:yarnTest \
#	-x :metadata-ingestion-modules:airflow-plugin:build \
#	-x :metadata-ingestion-modules:airflow-plugin:check \
#	-x :metadata-ingestion:build \
#	-x :metadata-ingestion:check \
#	-x :metadata-integration:java:datahub-client:checkShadowJar \
#	-x :metadata-integration:java:datahub-client:test \
#	-x :metadata-integration:java:datahub-protobuf:checkShadowJar \
#	-x :metadata-integration:java:spark-lineage:compileJava \
#	-x :metadata-integration:java:spark-lineage:shadowJar \
#	-x :metadata-integration:java:spark-lineage:test \
#	-x :metadata-io:test \
#	-x :metadata-service:auth-impl:test \
#	-x :metadata-service:plugin:test \
#	-x docs-website:build \
#	--parallel \
#	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
#	echo "Running Build and Test for all modules"; \
#	echo "Running Datahub Frontend build Task"; \
#	cd datahub-web-react; \
#	yarn cache clean; \
#	yarn --update-checksums; \
#	cd ..; \
#	git --no-pager diff; \
#	./gradlew --stacktrace :datahub-frontend:build :datahub-web-react:build \
#	--parallel; \

build:
	echo "Setting Gradle Wrapper Credentials for gradle download"; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	echo "Running Build and Test for all modules"; \
	./gradlew :metadata-service:war:build; \
#	./gradlew :datahub-frontend:assemble; \
	./gradlew :datahub-upgrade:build; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	echo "Running Datahub Frontend build Task"; \
#	cd datahub-web-react; \
#	yarn cache clean; \
#	yarn --update-checksums; \
#	cd ..; \
#	git --no-pager diff; \
	./gradlew :datahub-frontend:build --parallel;

package:
	echo "Setting Gradle Wrapper Credentials for gradle download"; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	export LANG=en_US.UTF-8; \
	export LC_ALL=$LANG; \
	export LANGUAGE=$LANG; \
	echo "Packaging Datahub Artifacts to folder: datahub-artifact"; \
	rm -rf datahub-artifact; \
	mkdir -p datahub-artifact; \
	mkdir -p datahub-artifact/datahub-gms; \
	mkdir -p datahub-artifact/datahub-frontend/datahub-frontend; \
	mkdir -p datahub-artifact/datahub-upgrade; \
	mkdir -p datahub-artifact/crawler-test; \
	mkdir -p datahub-artifact/certs; \
	mkdir -p datahub-artifact/setup/elasticsearch-setup; \
	mkdir -p datahub-artifact/setup/kafka-setup; \
	mkdir -p datahub-artifact/setup/mysql-setup; \
	mkdir -p datahub-artifact/resources; \
	echo "Current datahub-artifact folder tree"; \
	find datahub-artifact | sort | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"; \
	echo "1. Copying Datahub Frontend"; \
	tar -xvf datahub-frontend/build/distributions/datahub-frontend-*.tar -C datahub-artifact/datahub-frontend/datahub-frontend --strip-components 1; \
	echo "2. Copying Datahub Upgrade JAR"; \
	cp datahub-upgrade/build/libs/datahub-upgrade.jar datahub-artifact/datahub-upgrade; \
	echo "3. Copying Metadata Service WAR"; \
	cp metadata-service/war/build/libs/war.war datahub-artifact/datahub-gms; \
	echo "4. Copying Crawler Test JAR"; \
	echo "5. Copying entity-registry.yml"; \
	cp metadata-models/src/main/resources/entity-registry.yml datahub-artifact/resources; \
	echo "6. Copying elasticsearch json files"; \
	cp metadata-service/restli-servlet-impl/src/main/resources/index/usage-event/{index_template.json,policy.json} datahub-artifact/setup/elasticsearch-setup; \
	echo "7. Downloading jetty files"; \
	chmod u+x download.sh; \
	./download.sh; \
	echo "8. Downloading VISA Certificates"; \
	echo "9. Copying Datahub GMS files"; \
	cp docker/datahub-gms/jetty.xml datahub-artifact/datahub-gms; \
	echo "10. Copying Deploy Scripts"; \
	cp -a deploy-scripts/. datahub-artifact/; \
	echo "Final datahub-artifact folder tree"; \
	find datahub-artifact | sort | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"; \
	git --no-pager diff; \
	tar cvf ${TAR_BALL_VERSION}.tar datahub-artifact; \
	ls -lah ${TAR_BALL_VERSION}.tar; \
	echo "\n\nPackage Completed"
