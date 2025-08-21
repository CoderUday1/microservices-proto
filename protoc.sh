#!/bin/bash

SERVICE_NAME=$1
RELEASE_VERSION=$2
USER_NAME=$3
EMAIL=$4

# Configure git
git config user.name "$USER_NAME"
git config user.email "$EMAIL"

# Make sure we're on latest main
git fetch origin main
git checkout main
git pull origin main   # keep local in sync with remote

# Install required tools
sudo apt-get update
sudo apt-get install -y protobuf-compiler golang-goprotobuf-dev
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Generate proto files
protoc --go_out=./golang --go_opt=paths=source_relative \
  --go-grpc_out=./golang --go-grpc_opt=paths=source_relative \
  ./${SERVICE_NAME}/*.proto

# Init go module for this service
cd golang/${SERVICE_NAME}
rm go.mod
rm go.sum
go mod init github.com/CoderUday1/microservices-proto/golang/${SERVICE_NAME}" || true
go mod tidy
cd ../../

# Commit changes (skip if nothing new)
git add .
git commit -m "proto update for ${SERVICE_NAME}" || echo "No changes to commit"

# Push safely (rebase if needed)
git pull --rebase origin main
git push origin HEAD:main

# Create / update tag
git tag -fa golang/${SERVICE_NAME}/${RELEASE_VERSION} -m "golang/${SERVICE_NAME}/${RELEASE_VERSION}"
git push origin refs/tags/golang/${SERVICE_NAME}/${RELEASE_VERSION} --force
