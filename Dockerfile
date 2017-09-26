FROM centos/postgresql-95-centos7

USER root

ENV BACKUP_DATA_DIR=/tmp BACKUP_KEEP=2 BACKUP_MINUTE=* BACKUP_HOUR=*

RUN yum -y install epel-release && yum update -y
RUN yum -y install python \
    python-devel \
    python-pip \
    mercurial \
    openssh-clients \
    ed \
    yum clean all

# Install dev cron
RUN pip install -e hg+https://bitbucket.org/dbenamy/devcron#egg=devcron




#Test fix ssh with user random
RUN chmod 775 /var/run
RUN rm -f /var/run/nologin

RUN adduser --system -s /bin/bash -u 1234321 -g 0 backupuser # uid to replace later
RUN chmod 775 /etc/ssh /home # keep writable for openshift user group (root)
#RUN chmod 660 /etc/ssh/sshd_config
RUN chmod 664 /etc/passwd /etc/group # to help uid fix
RUN ln -s /home/backupuser /repos # nicer repo url

WORKDIR /opt/app-root/src

ADD ./bin ./bin

RUN chmod -R 777 /opt/app-root/src

USER backupuser


CMD echo -e ",s/1234321/`id -u`/g\\012 w" | ed -s /etc/passwd && \
    mkdir -p /home/backupuser/.ssh && \
    touch /home/backupuser/.ssh/authorized_keys && \
    chmod 700 /home/backupuser/.ssh && \
    chmod 600 /home/backupuser/.ssh/authorized_keys && \
    ./bin/run.sh