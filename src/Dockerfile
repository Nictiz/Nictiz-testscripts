FROM alpine:3.18
RUN apk upgrade
RUN apk add wget
RUN apk add openjdk11-jre-headless
RUN apk add wget
RUN mkdir /ant && cd /ant && wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.14-bin.tar.gz && tar -xvzf apache-ant-1.10.14-bin.tar.gz && rm apache-ant-1.10.14-bin.tar.gz
#ENV PATH=$PATH:/ant/apache-ant-1.10.14/bin
#RUN echo "export PATH=$PATH:/ant/apache-ant-1.10.14/bin" >> /etc/profile

RUN echo "#!/bin/ash" > /entrypoint.sh
#RUN echo "echo Hallo!" >> /entrypoint.sh
#RUN echo "echo \$type" >> /entrypoint.sh
#RUN echo "echo \$propertyfile" >> /entrypoint.sh
RUN echo "cat /repo/src/\$propertyfile" >> entrypoint.sh
RUN echo "if [[ \$type == \"single\" ]]; then ant -f /repo/src/build-single.xml -propertyfile \$propertyfile" >> /entrypoint.sh
RUN echo "elif [[ \$type == \"multiple\" ]]; then ant -f /repo/src/build-multiple.xml -propertyfile \$propertyfile" >> /entrypoint.sh
#RUN echo "elif [[ $1 -eq \"tree\" ]]; then" >> /entrypoint.sh
#RUN echo "    ant -f /repo/src/build-multiple.xml -propertyfile $2" >> /entrypoint.sh
#RUN echo "    ant -f /repo/src/build-centralizeLoadResources.xml -propertyfile $2" >> /entrypoint.sh
RUN echo "else echo Specify 'single', 'multiple' or 'tree' as the first argument" >> /entrypoint.sh
RUN echo "fi" >> /entrypoint.sh
RUN chmod a+x /entrypoint.sh

ENV PATH="${PATH}:/ant/apache-ant-1.10.14/bin"

#ENTRYPOINT ["/bin/ash", "--login"]
#ENTRYPOINT ["ant", "-f", "/repo/src/build-multiple.xml", "-propertyfile", "/repo/src/eOverdracht-4-0/build.properties"]
ENTRYPOINT ["/entrypoint.sh"]