# Assemblyline
## Shipping Agent

[![Build Status](https://travis-ci.org/assemblyline/shipping_agent.svg?branch=master)](https://travis-ci.org/assemblyline/shipping_agent)

Shipping Agent listens for Github Deployment Events on a Webhook.

### Configuration

Config is set up with environment variables.

|Name                    | Description|
|------------------------|------------|
|`GITHUB_WEBHOOK_SECRET` | The webhook secret [see](https://developer.github.com/v3/repos/hooks/#create-a-hook) |
|`LOG_LEVEL`             | The log level to use FATAL, ERROR, WARN, INFO or DEBUG. Defaults to WARN             |
