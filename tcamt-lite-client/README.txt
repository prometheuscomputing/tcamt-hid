TCAMT Lite — Frontend (tcamt-lite-client)
=========================================

Full build instructions: see ../BUILD.md

Quick start
-----------

  cd tcamt-lite-client
  nvm use              # Node 13.12.0 (.nvmrc)
  npm install          # from package-lock.json — do not npm update
  npx bower install    # first time only, if bower_components/ is missing
  npx grunt build --prod   # production assets → ../tcamt-lite-controller/src/main/webapp/
  cd ..
  mvn clean install -DskipTests

Output WAR: tcamt-lite-controller/target/tcamt.war

Development server
------------------

  npx grunt serve      # http://localhost:9000 (task is "serve", not "server")
