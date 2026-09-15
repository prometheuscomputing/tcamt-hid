FROM tomcat:9.0.105-jdk8-temurin-noble
RUN rm -rf /usr/local/tomcat/webapps/*
RUN rm -rf /usr/local/tomcat/webapps.dist
RUN sed -i '/<\/web-app>/i \
    <error-page>\n\
      <exception-type>java.lang.Throwable<\/exception-type>\n\
      <location>/error.html<\/location>\n\
    <\/error-page>\n \
    <error-page>\n\
      <error-code>0<\/error-code>\n\
      <location>/error.html<\/location>\n\
    <\/error-page>\n' /usr/local/tomcat/conf/web.xml
COPY ./error.html /usr/local/tomcat/webapps/ROOT/error.html
COPY ./tcamt-lite-controller/target/tcamt.war /usr/local/tomcat/webapps/tcamt.war

# The application authenticates against a JNDI datasource (jdbc/igl_jndi)
# that stock Tomcat does not declare. It is declared here with placeholders
# that docker/entrypoint.sh fills from DB_HOST, DB_PORT, DB_NAME, DB_USER and
# DB_PASSWORD at start; the entrypoint refuses to start while a placeholder
# survives. The other runtime settings (Mongo, mail relay, Froala key,
# version label, connect rewrite) are passed by the same entrypoint as
# system properties. See BUILD.md, "What a deployment sets at runtime".
RUN set -eu; \
    CTX=/usr/local/tomcat/conf/context.xml; \
    ! grep -q 'igl_jndi' "$CTX"; \
    sed -i 's#</Context>#    <Resource name="jdbc/igl_jndi" auth="Container" type="javax.sql.DataSource"\n        maxTotal="20" maxIdle="8" maxWaitMillis="10000"\n        driverClassName="com.mysql.jdbc.Driver"\n        url="jdbc:mysql://container-mysql:3306/tcamt_db?useSSL=false\&amp;allowPublicKeyRetrieval=true\&amp;useUnicode=TRUE\&amp;characterEncoding=UTF-8"\n        username="tcamt" password="db_password" />\n</Context>#' "$CTX"; \
    grep -q 'jdbc/igl_jndi' "$CTX"
COPY ./docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
