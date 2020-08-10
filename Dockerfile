FROM openjdk:8-jdk-alpine

COPY target/spring-petclinic-2.3.1.BUILD-SNAPSHOT.jar /petclinic.jar

RUN apk add git
RUN git clone https://github.com/aquasecurity/trivy-ci-test.git
RUN mkdir /ruby-app
RUN cp trivy-ci-test/Gemfile_rails.lock /ruby-app/Gemfile.lock

ENTRYPOINT ["java","-jar","/petclinic.jar"]
EXPOSE 8080