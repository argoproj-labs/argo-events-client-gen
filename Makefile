GIT_ORG    := argoproj
GIT_BRANCH := $(shell git rev-parse --abbrev-ref=loose HEAD | sed 's/heads\///')
VERSION    := HEAD

# VERSION as GIT_BRANCH must be different
ifneq ($(VERSION),$(GIT_BRANCH))

SWAGGER    := https://raw.githubusercontent.com/$(GIT_ORG)/argo-events/$(VERSION)/api/openapi-spec/swagger.json

clients: java

.PHONY: clean
clean:
	rm -Rf dist

dist/swagger.json:
	curl -L -o dist/swagger.json $(SWAGGER)

dist/openapi-generator-cli.jar:
	mkdir -p dist
	curl -L -o dist/openapi-generator-cli.jar https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/4.2.3/openapi-generator-cli-4.2.3.jar

# java client

ifeq ($(VERSION),HEAD)
JAVA_CLIENT_VERSION := 1-SNAPSHOT
else
JAVA_CLIENT_VERSION := $(VERSION)
endif
JAVA_CLIENT_JAR     := $(HOME)/.m2/repository/io/argoproj/workflow/argo-client-java/$(JAVA_CLIENT_VERSION)/argo-client-java-$(JAVA_CLIENT_VERSION).jar

dist/common.swagger.json: dist/swagger.json
	cat dist/swagger.json | ./hack/swaggerfilter.py io.argoproj.common | sed 's/io.argoproj.common.//' | sed 's/io.k8s.api.core.//' | sed 's/io.k8s.apimachinery.pkg.apis.meta.//'   > dist/common.swagger.json
dist/eventbus.swagger.json: dist/swagger.json
	cat dist/swagger.json | ./hack/swaggerfilter.py io.argoproj.eventbus.v1alpha1 | sed 's/io.argoproj.common.//' | sed 's/io.argoproj.eventbus.v1alpha1.//' | sed 's/io.k8s.api.core.//' | sed 's/io.k8s.apimachinery.pkg.apis.meta.//' | sed 's/io.k8s.apimachinery.pkg.api.resource./resource./'  > dist/eventbus.swagger.json
dist/eventsource.swagger.json: dist/swagger.json
	cat dist/swagger.json | ./hack/swaggerfilter.py io.argoproj.eventsource.v1alpha1 | sed 's/io.argoproj.common.//' | sed 's/io.argoproj.eventsource.v1alpha1.//' | sed 's/io.k8s.api.core.//' | sed 's/io.k8s.apimachinery.pkg.apis.meta.//' > dist/eventsource.swagger.json
dist/sensor.swagger.json: dist/swagger.json
	cat dist/swagger.json | ./hack/swaggerfilter.py io.argoproj.sensor.v1alpha1 | sed 's/io.argoproj.common.//' | sed 's/io.argoproj.sensor.v1alpha1.//' | sed 's/io.k8s.api.core.//' | sed 's/io.k8s.apimachinery.pkg.apis.meta.//' > dist/sensor.swagger.json

.PHONY: java
java: $(JAVA_CLIENT_JAR)

$(JAVA_CLIENT_JAR): dist/openapi-generator-cli.jar dist/common.swagger.json dist/eventbus.swagger.json dist/eventsource.swagger.json dist/sensor.swagger.json
	git submodule update --remote --init java
	cd java && git checkout -b $(GIT_BRANCH) || git checkout $(GIT_BRANCH)
	rm -Rf java/*
	# Common
	java \
		-jar dist/openapi-generator-cli.jar \
		generate \
		-i dist/common.swagger.json \
		-g java \
		-o java \
		-p hideGenerationTimestamp=true \
		-p dateLibrary=joda \
		--api-package io.argoproj.events.apis \
		--invoker-package io.argoproj.events \
		--model-package io.argoproj.events.models.common \
		--group-id io.argoproj.events \
		--artifact-id argo-events-client-java \
		--artifact-version $(JAVA_CLIENT_VERSION) \
		--import-mappings V1Time=org.joda.time.DateTime \
		--type-mappings V1Time=org.joda.time.DateTime \
		--import-mappings V1ConfigMapKeySelector=io.kubernetes.client.openapi.models.V1ConfigMapKeySelector \
		--import-mappings V1SecretKeySelector=io.kubernetes.client.openapi.models.V1SecretKeySelector \
		--generate-alias-as-model
	# EventBus
	java \
		-jar dist/openapi-generator-cli.jar \
		generate \
		-i dist/eventbus.swagger.json \
		-g java \
		-o java \
		-p hideGenerationTimestamp=true \
		-p dateLibrary=joda \
		--api-package io.argoproj.events.apis \
		--invoker-package io.argoproj.events \
		--model-package io.argoproj.events.models.eventbus \
		--group-id io.argoproj.events \
		--artifact-id argo-events-client-java \
		--artifact-version $(JAVA_CLIENT_VERSION) \
		--import-mappings V1Time=org.joda.time.DateTime \
		--type-mappings V1Time=org.joda.time.DateTime \
		--import-mappings V1Affinity=io.kubernetes.client.openapi.models.V1Affinity \
		--import-mappings V1ConfigMapKeySelector=io.kubernetes.client.openapi.models.V1ConfigMapKeySelector \
		--import-mappings V1Container=io.kubernetes.client.openapi.models.V1Container \
		--import-mappings V1ContainerPort=io.kubernetes.client.openapi.models.V1ContainerPort \
		--import-mappings V1EnvFromSource=io.kubernetes.client.openapi.models.V1EnvFromSource \
		--import-mappings V1EnvVar=io.kubernetes.client.openapi.models.V1EnvVar \
		--import-mappings V1HostAlias=io.kubernetes.client.openapi.models.V1HostAlias \
		--import-mappings V1Lifecycle=io.kubernetes.client.openapi.models.V1Lifecycle \
		--import-mappings V1ListMeta=io.kubernetes.client.openapi.models.V1ListMeta \
		--import-mappings V1LocalObjectReference=io.kubernetes.client.openapi.models.V1LocalObjectReference \
		--import-mappings V1ObjectMeta=io.kubernetes.client.openapi.models.V1ObjectMeta \
		--import-mappings V1ObjectReference=io.kubernetes.client.openapi.models.V1ObjectReference \
		--import-mappings V1PersistentVolumeClaim=io.kubernetes.client.openapi.models.V1PersistentVolumeClaim \
		--import-mappings V1PodDisruptionBudgetSpec=io.kubernetes.client.openapi.models.V1beta1PodDisruptionBudgetSpec \
		--import-mappings V1PodDNSConfig=io.kubernetes.client.openapi.models.V1PodDNSConfig \
		--import-mappings V1PodSecurityContext=io.kubernetes.client.openapi.models.V1PodSecurityContext \
		--import-mappings V1Probe=io.kubernetes.client.openapi.models.V1Probe \
		--import-mappings V1ResourceRequirements=io.kubernetes.client.openapi.models.V1ResourceRequirements \
		--import-mappings V1SecretKeySelector=io.kubernetes.client.openapi.models.V1SecretKeySelector \
		--import-mappings V1SecurityContext=io.kubernetes.client.openapi.models.V1SecurityContext \
		--import-mappings V1Toleration=io.kubernetes.client.openapi.models.V1Toleration \
		--import-mappings V1Volume=io.kubernetes.client.openapi.models.V1Volume \
		--import-mappings V1VolumeDevice=io.kubernetes.client.openapi.models.V1VolumeDevice \
		--import-mappings V1VolumeMount=io.kubernetes.client.openapi.models.V1VolumeMount \
		--import-mappings ResourceQuantity=io.kubernetes.client.custom.Quantity \
		--type-mappings ResourceQuantity=io.kubernetes.client.custom.Quantity \
		--import-mappings Condition=io.argoproj.events.models.common.Condition \
		--generate-alias-as-model
	# EventSource
	java \
		-jar dist/openapi-generator-cli.jar \
		generate \
		-i dist/eventsource.swagger.json \
		-g java \
		-o java \
		-p hideGenerationTimestamp=true \
		-p dateLibrary=joda \
		--api-package io.argoproj.events.apis \
		--invoker-package io.argoproj.events \
		--model-package io.argoproj.events.models.eventsource \
		--group-id io.argoproj.events \
		--artifact-id argo-events-client-java \
		--artifact-version $(JAVA_CLIENT_VERSION) \
		--import-mappings V1Time=org.joda.time.DateTime \
		--type-mappings V1Time=org.joda.time.DateTime \
		--import-mappings V1Affinity=io.kubernetes.client.openapi.models.V1Affinity \
		--import-mappings V1ConfigMapKeySelector=io.kubernetes.client.openapi.models.V1ConfigMapKeySelector \
		--import-mappings V1Container=io.kubernetes.client.openapi.models.V1Container \
		--import-mappings V1ContainerPort=io.kubernetes.client.openapi.models.V1ContainerPort \
		--import-mappings V1EnvFromSource=io.kubernetes.client.openapi.models.V1EnvFromSource \
		--import-mappings V1EnvVar=io.kubernetes.client.openapi.models.V1EnvVar \
		--import-mappings V1HostAlias=io.kubernetes.client.openapi.models.V1HostAlias \
		--import-mappings V1Lifecycle=io.kubernetes.client.openapi.models.V1Lifecycle \
		--import-mappings V1ListMeta=io.kubernetes.client.openapi.models.V1ListMeta \
		--import-mappings V1LocalObjectReference=io.kubernetes.client.openapi.models.V1LocalObjectReference \
		--import-mappings V1ObjectMeta=io.kubernetes.client.openapi.models.V1ObjectMeta \
		--import-mappings V1ObjectReference=io.kubernetes.client.openapi.models.V1ObjectReference \
		--import-mappings V1PersistentVolumeClaim=io.kubernetes.client.openapi.models.V1PersistentVolumeClaim \
		--import-mappings V1PodDisruptionBudgetSpec=io.kubernetes.client.openapi.models.V1beta1PodDisruptionBudgetSpec \
		--import-mappings V1PodDNSConfig=io.kubernetes.client.openapi.models.V1PodDNSConfig \
		--import-mappings V1PodSecurityContext=io.kubernetes.client.openapi.models.V1PodSecurityContext \
		--import-mappings V1Probe=io.kubernetes.client.openapi.models.V1Probe \
		--import-mappings V1ResourceRequirements=io.kubernetes.client.openapi.models.V1ResourceRequirements \
		--import-mappings V1SecretKeySelector=io.kubernetes.client.openapi.models.V1SecretKeySelector \
		--import-mappings V1SecurityContext=io.kubernetes.client.openapi.models.V1SecurityContext \
		--import-mappings V1Toleration=io.kubernetes.client.openapi.models.V1Toleration \
		--import-mappings V1Volume=io.kubernetes.client.openapi.models.V1Volume \
		--import-mappings V1VolumeDevice=io.kubernetes.client.openapi.models.V1VolumeDevice \
		--import-mappings V1VolumeMount=io.kubernetes.client.openapi.models.V1VolumeMount \
		--import-mappings V1ServicePort=io.kubernetes.client.openapi.models.V1ServicePort \
		--import-mappings Condition=io.argoproj.events.models.common.Condition \
		--import-mappings TLSConfig=io.argoproj.events.models.common.TLSConfig \
		--import-mappings Backoff=io.argoproj.events.models.common.Backoff \
		--import-mappings S3Artifact=io.argoproj.events.models.common.S3Artifact \
		--generate-alias-as-model
	# Sensor
	java \
		-jar dist/openapi-generator-cli.jar \
		generate \
		-i dist/sensor.swagger.json \
		-g java \
		-o java \
		-p hideGenerationTimestamp=true \
		-p dateLibrary=joda \
		--api-package io.argoproj.events.apis \
		--invoker-package io.argoproj.events \
		--model-package io.argoproj.events.models.sensor \
		--group-id io.argoproj.events \
		--artifact-id argo-events-client-java \
		--artifact-version $(JAVA_CLIENT_VERSION) \
		--import-mappings V1Time=org.joda.time.DateTime \
		--type-mappings V1Time=org.joda.time.DateTime \
		--import-mappings V1Affinity=io.kubernetes.client.openapi.models.V1Affinity \
		--import-mappings V1ConfigMapKeySelector=io.kubernetes.client.openapi.models.V1ConfigMapKeySelector \
		--import-mappings V1Container=io.kubernetes.client.openapi.models.V1Container \
		--import-mappings V1ContainerPort=io.kubernetes.client.openapi.models.V1ContainerPort \
		--import-mappings V1EnvFromSource=io.kubernetes.client.openapi.models.V1EnvFromSource \
		--import-mappings V1EnvVar=io.kubernetes.client.openapi.models.V1EnvVar \
		--import-mappings V1HostAlias=io.kubernetes.client.openapi.models.V1HostAlias \
		--import-mappings V1Lifecycle=io.kubernetes.client.openapi.models.V1Lifecycle \
		--import-mappings V1ListMeta=io.kubernetes.client.openapi.models.V1ListMeta \
		--import-mappings V1LocalObjectReference=io.kubernetes.client.openapi.models.V1LocalObjectReference \
		--import-mappings V1ObjectMeta=io.kubernetes.client.openapi.models.V1ObjectMeta \
		--import-mappings V1ObjectReference=io.kubernetes.client.openapi.models.V1ObjectReference \
		--import-mappings V1PersistentVolumeClaim=io.kubernetes.client.openapi.models.V1PersistentVolumeClaim \
		--import-mappings V1PodDisruptionBudgetSpec=io.kubernetes.client.openapi.models.V1beta1PodDisruptionBudgetSpec \
		--import-mappings V1PodDNSConfig=io.kubernetes.client.openapi.models.V1PodDNSConfig \
		--import-mappings V1PodSecurityContext=io.kubernetes.client.openapi.models.V1PodSecurityContext \
		--import-mappings V1Probe=io.kubernetes.client.openapi.models.V1Probe \
		--import-mappings V1ResourceRequirements=io.kubernetes.client.openapi.models.V1ResourceRequirements \
		--import-mappings V1SecretKeySelector=io.kubernetes.client.openapi.models.V1SecretKeySelector \
		--import-mappings V1SecurityContext=io.kubernetes.client.openapi.models.V1SecurityContext \
		--import-mappings V1Toleration=io.kubernetes.client.openapi.models.V1Toleration \
		--import-mappings V1Volume=io.kubernetes.client.openapi.models.V1Volume \
		--import-mappings V1VolumeDevice=io.kubernetes.client.openapi.models.V1VolumeDevice \
		--import-mappings V1VolumeMount=io.kubernetes.client.openapi.models.V1VolumeMount \
		--import-mappings Condition=io.argoproj.events.models.common.Condition \
		--import-mappings TLSConfig=io.argoproj.events.models.common.TLSConfig \
		--import-mappings Backoff=io.argoproj.events.models.common.Backoff \
		--import-mappings S3Artifact=io.argoproj.events.models.common.S3Artifact \
		--import-mappings Resource=java.lang.Object \
		--generate-alias-as-model
	# add the io.kubernetes:java-client to the deps
	cd java && sed 's/<dependencies>/<dependencies><dependency><groupId>io.kubernetes<\/groupId><artifactId>client-java<\/artifactId><version>9.0.0<\/version><\/dependency>/g' pom.xml > tmp && mv tmp pom.xml
    
	cd java && mvn package -Dmaven.javadoc.skip
	cd java && git add .
	cd java && git diff --exit-code || git commit -m 'Updated to $(JAVA_CLIENT_VERSION)'
ifneq ($(VERSION),HEAD)
	git tag -f $(VERSION)
endif
	cd java && mvn install -DskipTests -Dmaven.javadoc.skip
	git add java

.PHONY: test-java
test-java: java-test/target/ok

java-test/target/ok: $(JAVA_CLIENT_JAR)
	cd java-test && mvn versions:set -DnewVersion=$(JAVA_CLIENT_VERSION) verify
	touch java-test/target/ok

.PHONY: publish-java
publish-java: test-java
	# https://help.github.com/en/packages/using-github-packages-with-your-projects-ecosystem/configuring-apache-maven-for-use-with-github-packages
	cd java && mvn deploy -DskipTests -Dmaven.javadoc.skip -DaltDeploymentRepository=github::default::https://maven.pkg.github.com/argoproj-labs/argo-events-client-java
	cd java && git push origin $(GIT_BRANCH)
	$(make) tag-java

.PHONY: tag-java
tag-java:
ifneq ($(VERSION),HEAD)
	cd java && git tag $(VERSION)
	cd java && git push origin $(VERSION)
endif

endif
