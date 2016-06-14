# Assemblyline
## Shipping Agent

[![Build Status](https://travis-ci.org/assemblyline/shipping_agent.svg?branch=master)](https://travis-ci.org/assemblyline/shipping_agent)

Shipping Agent listens for Github Deployment Events on a Webhook, and updates Kubernetes to deploy new code.
While the update of the deployment is in progress Shipping Agent adds Github Deployment statuses to
update the user.

### Configuration

Config is set up with environment variables.

|Name                    | Description|
|------------------------|------------|
|`GITHUB_WEBHOOK_SECRET` | The webhook secret [see](https://developer.github.com/v3/repos/hooks/#create-a-hook) |
|`LOG_LEVEL`             | The log level to use FATAL, ERROR, WARN, INFO or DEBUG. Defaults to WARN             |
|`GITHUB_TOKEN`          | The Github OAuth token used for notifications                                        |
