

//
// Copyright (c) PavedRoad. All rights reserved.
// Licensed under the Apache2. See LICENSE file in the project root for full license information.
//

// User project / copyright / usage information
// Manage database of films

package main

import (
  "database/sql"
  "github.com/gorilla/mux"
  "log"
  "time"
)

// Contants to build up a k8s style URL
const (
  // FilmsAPIVersion Version API URL
  FilmsAPIVersion string = "/api/v1"
  // FilmsNamespaceID Prefix for namespaces
  FilmsNamespaceID string = "namespace"
  // FilmsDefaultNamespace Default namespace
  FilmsDefaultNamespace string = "pavedroad.io"
  // FilmsResourceType CRD Type per k8s
  FilmsResourceType string = "Films"
  // The email or account login used by 3rd parth provider
  FilmsKey string = "/{key}"
)

// Options for looking up a user
const (
  UUID = iota
  NAME
)

// holds pointers to database and http server
type FilmsApp struct {
  Router *mux.Router
  DB     *sql.DB
}

// both db and http configuration can be changed using environment varialbes
type databaseConfig struct {
  username string
  password string
  database string
  sslMode  string
  dbDriver string
  ip       string
  port     string
}

// HTTP server configuration
type httpConfig struct {
  ip              string
  port            string
  shutdownTimeout time.Duration
  readTimeout     time.Duration
  writeTimeout    time.Duration
  listenString    string
  logPath         string
}

// Global for use in the module

// Set default database configuration
var dbconf = databaseConfig{username: "root", password: "", database: "pavedroad", sslMode: "disable", dbDriver: "postgres", ip: "127.0.0.1", port: "26257"}

// Set default http configuration
var httpconf = httpConfig{ip: "127.0.0.1", port: "8082", shutdownTimeout: 15, readTimeout: 60, writeTimeout: 60, listenString: "127.0.0.1:8082", logPath: "logs/films.log"}

// shutdownTimeout will be initialized based on the default or HTTP_SHUTDOWN_TIMEOUT
var shutdowTimeout time.Duration

// main entry point for server
func main() {

  // Setup loggin
  openLogFile(httpconf.logPath)
  log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)
  log.Printf("Logfile opened %s", httpconf.logPath)

  a := FilmsApp{}
  a.Initialize()
  a.Run(httpconf.listenString)
}