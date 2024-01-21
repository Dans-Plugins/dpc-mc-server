FROM ubuntu

# Install dependencies
RUN apt-get update
RUN apt-get install -y git \
    openjdk-17-jdk \
    openjdk-17-jre \
    wget

# Create server directory
WORKDIR /dpcmcserver

# Build server
RUN wget -O BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
RUN git config --global --unset core.autocrlf || :
RUN java -jar BuildTools.jar --rev 1.20.4
RUN echo "eula=true" > eula.txt
RUN mkdir plugins

# Download & install Medieval Factions
WORKDIR /dpcmcserver/plugins
RUN wget https://github.com/Dans-Plugins/Medieval-Factions/releases/download/v5.3.0/medieval-factions-5.3.0-all.jar
WORKDIR /dpcmcserver

# Run server
EXPOSE 25565
EXPOSE 8123
ENTRYPOINT java -jar spigot-1.20.4.jar