FROM public.ecr.aws/n1q6t7z8/openjdk:latest

COPY target/spring-petclinic-2.3.0.BUILD-SNAPSHOT.jar /petclinic.jar

RUN apk add git
RUN git clone https://github.com/aquasecurity/trivy-ci-test.git
RUN mkdir /ruby-app
RUN cp trivy-ci-test/Gemfile_rails.lock /ruby-app/Gemfile.lock

ENTRYPOINT ["java","-jar","/petclinic.jar"]
EXPOSE 8080