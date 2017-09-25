FROM centos/postgresql-95-centos7

USER root

ENV BACKUP_DATA_DIR=/tmp BACKUP_KEEP=2 BACKUP_MINUTE=* BACKUP_HOUR=*

RUN yum -y install epel-release && yum update -y
RUN yum -y install python \
    python-devel \
    python-pip \
    mercurial \
    yum clean all

# Install dev cron
RUN pip install -e hg+https://bitbucket.org/dbenamy/devcron#egg=devcron

WORKDIR /opt/app-root/src

ADD ./bin ./bin
ADD ./ssh_key ./ssh_key
RUN chmod -R 777 /opt/app-root/src

USER 1001

CMD ./bin/run.sh