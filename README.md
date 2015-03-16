# Assemblyline
## Shipping Agent

This service orchestrates submission of releases to the Assemblyline cluster.

Stores state about applications, builds and releases to etcd, and interfaces
fleet to ship builds to the cluster.

Exposes a HTTP API to clients in order to register builds and submit them to
fleet.
