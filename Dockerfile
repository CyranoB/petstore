FROM openjdk:8-jdk-alpine

COPY target/spring-petclinic-2.3.1.BUILD-SNAPSHOT.jar /petclinic.jar
ENTRYPOINT ["java","-jar","/petclinic.jar"]
EXPOSE 8080