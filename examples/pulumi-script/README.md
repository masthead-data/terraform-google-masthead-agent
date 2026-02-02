# Masthead Agent Pulumi Deployment

This repository contains an example of Pulumi configuration for deploying the Masthead Agent on Google Cloud Platform (GCP).

## Prerequisites

Install Pulumi CLI:

    ```bash
    brew install pulumi/tap/pulumi
    ```

## Setup

1. Install required Python packages:

    ```bash
    pulumi package add terraform-module masthead-data/masthead-agent/google 0.3.0 masthead-agent
    ```

2. Configure Masthead Agent stack - [see example](./__main__.py) for reference.

3. Preview Pulumi project resources:

    ```bash
    pulumi preview
    ```
