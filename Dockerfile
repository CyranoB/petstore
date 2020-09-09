FROM amazoncorretto:8

COPY target/spring-petclinic-2.3.0.BUILD-SNAPSHOT.jar /petclinic.jar

ENTRYPOINT ["java","-jar","/petclinic.jar"]
EXPOSE 8080