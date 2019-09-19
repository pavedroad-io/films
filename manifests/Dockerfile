
# User golang based off al Alpine
FROM golang:latest

LABEL "vendor": "acme" \
      "microservice": "films" \
      "description": "Manage database of films" \
      "version": "1.0.0" \
      "tempalte": "datamgr" \
      "definition": "films.yaml" \
      "env": "dev"

MAINTAINER "support@pavedroad.io"

# Build paths for placing kevlar microservice
ENV ms films
ENV pavedroad /pavedroad
ENV pavedroadbin $pavedroad/$ms

# make working directory, move to it, and copy in prToken ms
RUN mkdir ${pavedroad}
WORKDIR ${pavedroad}
COPY $ms $pavedroad

EXPOSE 8081
CMD ["/bin/sh", "-c", "$pavedroadbin"]
