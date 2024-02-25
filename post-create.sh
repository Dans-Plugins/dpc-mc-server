echo "Running 'post-create.sh' script..."
if [ -z "$(ls -A /dpcmcserver)" ]; then
    echo "Setting up server..."
    # Copy server JAR
    cp /dpcmcserver-build/spigot-1.20.4.jar /dpcmcserver/spigot-1.20.4.jar

    # Create plugins directory
    mkdir /dpcmcserver/plugins

    # Copy JARs
    cp /jars/*.jar /dpcmcserver/plugins

    # Copy config files
    cp /config/ops.json /dpcmcserver

    # Accept EULA
    cd /dpcmcserver && echo "eula=true" > eula.txt
else
    echo "Server is already set up."
fi

java -jar /dpcmcserver/spigot-1.20.4.jar