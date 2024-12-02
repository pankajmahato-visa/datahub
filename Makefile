TAG ?= $(eval TAG := $(shell git describe --tags --always --dirty)-$(shell git diff | sha256sum | cut -c -6))$(TAG)
TAG_VERSION=$(subst -e3b0c4,,$(TAG))
TAR_BALL_VERSION="datahub-"$(subst -,.,$(TAG_VERSION))
DATAHUB_FRONTEND_VERSION ?= $(shell ./gradlew :datahub-frontend:properties --no-daemon --console=plain -q | grep "^version:" | awk '{printf $$2}')
.PHONY: init test clean build package

init:
	echo "TAG:" ${TAG}; \
	echo "TAG_VERSION:" ${TAG_VERSION}; \
	echo "TAR_BALL_VERSION:" ${TAR_BALL_VERSION}; \
	echo "DATAHUB_FRONTEND_VERSION:" ${DATAHUB_FRONTEND_VERSION}; \
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
	echo "Processor count"; \
	getconf _NPROCESSORS_ONLN; \
	echo "Total Memory(MB)"; \
	OSTYPE=$$(uname); \
	if [[ "$$OSTYPE" == "Linux" ]]; then \
		free -m | awk 'NR==2{print $$2}'; \
	elif [[ "$$OSTYPE" == "Darwin" ]]; then \
		sysctl -n hw.memsize | awk '{print $$1/(1024*1024)}'; \
	else \
		echo "Unknown OS"; \
	fi

clean:
	echo "Setting Gradle Wrapper Credentials for gradle download"; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	export LANG=en_US.UTF-8; \
	export LANGUAGE=en_US.UTF-8; \
	export LC_ALL=en_US.UTF-8; \
	echo "Running Complete Datahub Clean Task"; \
	./gradlew :metadata-service:war:clean :metadata-jobs:mae-consumer-job:clean :metadata-jobs:mce-consumer-job:clean :datahub-upgrade:clean :datahub-frontend:clean --parallel

test:
	echo "Setting Gradle Wrapper Credentials for gradle download"; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	export LANG=en_US.UTF-8; \
	export LANGUAGE=en_US.UTF-8; \
	export LC_ALL=en_US.UTF-8; \
	echo "Running Test for all modules"; \
	./gradlew :metadata-service:war:test :datahub-frontend:test :datahub-upgrade:test :metadata-jobs:mae-consumer-job:test :metadata-jobs:mce-consumer-job:test --parallel;

build:
	echo "Setting Gradle Wrapper Credentials for gradle download"; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	export LANG=en_US.UTF-8; \
	export LANGUAGE=en_US.UTF-8; \
	export LC_ALL=en_US.UTF-8; \
	echo "Running Build and Test for all modules"; \
	./gradlew :metadata-service:war:build :metadata-jobs:mae-consumer-job:build :metadata-jobs:mce-consumer-job:build :datahub-upgrade:build :datahub-frontend:build -x test --parallel;

package:
	echo "Setting Gradle Wrapper Credentials for gradle download"; \
	export GRADLE_OPTS="-Dgradle.wrapperUser=$$PIPER_CUSTOM_USER -Dgradle.wrapperPassword=$$PIPER_CUSTOM_PASSWORD"; \
	export LANG=en_US.UTF-8; \
	export LANGUAGE=en_US.UTF-8; \
	export LC_ALL=en_US.UTF-8; \
	echo "Packaging Datahub Artifacts to folder: datahub-artifact"; \
	rm -rf datahub-artifact; \
	mkdir -p datahub-artifact; \
	mkdir -p datahub-artifact/datahub-gms; \
	mkdir -p datahub-artifact/datahub-mae-consumer; \
	mkdir -p datahub-artifact/datahub-mce-consumer; \
	mkdir -p datahub-artifact/datahub-frontend/datahub-frontend; \
	mkdir -p datahub-artifact/datahub-upgrade; \
	mkdir -p datahub-artifact/crawler-test; \
	mkdir -p datahub-artifact/certs; \
	mkdir -p datahub-artifact/setup/elasticsearch-setup; \
	mkdir -p datahub-artifact/setup/kafka-setup; \
	mkdir -p datahub-artifact/setup/mysql-setup; \
	mkdir -p datahub-artifact/resources; \
	mkdir -p datahub-artifact/plugins/retention; \
	echo "Current datahub-artifact folder tree"; \
	find datahub-artifact | sort | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"; \
	echo "1. Copying Datahub Frontend"; \
	tar -xvf datahub-frontend/build/distributions/datahub-frontend-${DATAHUB_FRONTEND_VERSION}.tar -C datahub-artifact/datahub-frontend/datahub-frontend --strip-components 1; \
	echo "2. Copying Datahub Upgrade JAR"; \
	cp datahub-upgrade/build/libs/datahub-upgrade.jar datahub-artifact/datahub-upgrade; \
	echo "3. Copying Metadata Service WAR"; \
	cp metadata-service/war/build/libs/war.war datahub-artifact/datahub-gms; \
	echo "4. Copying MAE Consumer Jar"; \
	cp metadata-jobs/mae-consumer-job/build/libs/mae-consumer-job.jar datahub-artifact/datahub-mae-consumer; \
	echo "5. Copying MCE Consumer Jar"; \
	cp metadata-jobs/mce-consumer-job/build/libs/mce-consumer-job.jar datahub-artifact/datahub-mce-consumer; \
	echo "6. Copying Crawler Test JAR"; \
	echo "7. Copying entity-registry.yml"; \
	cp metadata-models/src/main/resources/entity-registry.yml datahub-artifact/resources; \
	echo "8. Copying spark-lineage-retention.yaml"; \
	cp deploy-scripts/spark-lineage-retention.yaml datahub-artifact/plugins/retention; \
	echo "9. Copying elasticsearch json files"; \
	cp metadata-service/restli-servlet-impl/src/main/resources/index/usage-event/{index_template.json,policy.json} datahub-artifact/setup/elasticsearch-setup; \
	echo "10. Downloading jetty files"; \
	chmod u+x download.sh; \
	./download.sh; \
	echo "11. Downloading VISA Certificates"; \
	echo "12. Copying Datahub GMS files"; \
	cp docker/datahub-gms/jetty.xml datahub-artifact/datahub-gms; \
	cp docker/datahub-gms/jetty-jmx.xml datahub-artifact/datahub-gms; \
	echo "13. Copying Deploy Scripts"; \
	cp -a deploy-scripts/. datahub-artifact/; \
	echo "Final datahub-artifact folder tree"; \
	find datahub-artifact | sort | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"; \
	git --no-pager diff; \
	tar cvf ${TAR_BALL_VERSION}.tar datahub-artifact; \
	ls -lah ${TAR_BALL_VERSION}.tar; \
	echo "\n\nPackage Completed"
