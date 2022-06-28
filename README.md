# circleci-cicd-pipeline
Circleci Pipeline to deploy a web application

![Solution Architecture](/docs/screenshots/circleci_cicd_pipeline.png)

# Solution overview

. Circleci CI/CD Pipeline

. Source control GIT Workflow

. AWS CloudFormation for Infrastructure As Code

. Ansible for Configuration As Code

. Docker builds

. Docker Cloud Test servers e.g SonarCloud

. JIRA issue integration

. Slack issue notification

- Security

. Multi IAM users Circleci pipeline job step execution i.e IAM users such as Admin(security), Database Admin , DevOps team and web developers each have different priviledges in setting up infrastructure and configuration. An example of how different teams have to collaborate.

. Use of restricted context to store github or bitbucket secrets in Circleci.

. Use of AWS secret manager and KMS to store sensitive details such as database username and password. 
These details can only be shared with the credentials of an authorize IAM user such as Admin(security) or Database Admin.
Secrets can be rotated without the need of manually deleting and adding new environment variables in Circleci context.

- Features

. Status sync with Circleci pipeline when deploying infrastructure to AWS

. Git Push command available in Circleci job step to commit for example audit fixes back to master

# Build

![Build screenshot1-2](/docs/screenshots/SCREENSHOT01-2.png)

![Build screenshot1-3](/docs/screenshots/SCREENSHOT01-3.png)

- Triggers (check commit message before build and stop automatic builds)

![Build screenshot1_trigger](/docs/screenshots/SCREENSHOT01_trigger.png)

# Test

![Test screenshot2](/docs/screenshots/SCREENSHOT02-1.png)

![Test screenshot2 Fix](/docs/screenshots/SCREENSHOT02-2.png)

- Triggers (nightly tests)

![Test screenshot2 nightly](/docs/screenshots/SCREENSHOT02_nightly.png)

# Audit

![Audit screenshot3](/docs/screenshots/SCREENSHOT03.png)

![Audit screenshot3 frontend](/docs/screenshots/SCREENSHOT03_frontend.png)

![Audit screenshot3 Jira](/docs/screenshots/SCREENSHOT03_fixed_jira.png)

- SonarQube integration with circleci

![Audit screenshot3](/docs/screenshots/SCREENSHOT03_sonarqube.png)

![Audit screenshot3](/docs/screenshots/SCREENSHOT03_sonarqube2.png)

- Create project at [SonarCloud](https://sonarcloud.io/)
- Add scan job to pipeline with SonarCloud details of organisation and project created
- Add SONAR_TOKEN environment to circleci project
- Run circleci scan job and report will be posted to SonarCloud project area (or configure where to post scan reports)

# Notification Setup

![Jira screenshot1](/docs/screenshots/SCREENSHOT02_jira.png)

![Slack screenshot1](/docs/screenshots/SCREENSHOT04_slack.png)

![Slack screenshot1](/docs/screenshots/SCREENSHOT04_slack2.png)

# JIRA integration with Circleci

    orbs:

      jira: circleci/jira@1.3.1

- Install Circleci App in JIRA. Click on Get started and copy Token to
- Circleci : Project settings > Jira Integration
- Circleci: Personal settings > Create Access Token and copy Token to
- Circleci : Project settings > Environment Variables > CIRCLE_TOKEN

  
# Slack integration with Circleci

    orbs: 

      slack: circleci/slack@4.10.1

- To obtain a Bot Auth follow steps in [Connecting Circleci to Slack](https://github.com/CircleCI-Public/slack-orb/wiki/Setup) and Copy to 
- Circleci : Project settings > Environment Variables > SLACK_ACCESS_TOKEN
- Circleci : Project settings > Environment Variables > SLACK_DEFAULT_CHANNEL

# Deploy - Infrastructure Phase

- Create/Deploy Infrastructure to AWS

The main challenge is to sync aws stack events with circleci pipeline steps. 
Since I've also added a multi IAM user step execution in the circleci pipeline,
you also have to deal with IAM user priviledges.

Here is a screenshot of when there is a conflict of change-set status if the timing is wrong of executing an update while another is in cleanup/deleted after a successful previous update.

![Timing conflict](/docs/screenshots/SCREENSHOT05.png)

To get it right you need an event loop to wait for a signal before moving to the next step.

![Wait loop](/docs/screenshots/SCREENSHOT05_loop.png)

And here is another when an IAM user with the wrong priviledges executes an unauthorized step.

![Unauthorized execution](/docs/screenshots/SCREENSHOT05_unauth.png)

To solve this you need to know when to configure aws cli for each IAM user before executing the step.

You can see in this link a [screenshoot](/docs/screenshots/SCREENSHOT05_steps.png) of all the steps to ensure the frontend and backend aws infrastructure exist. Most of the time is spent on the Creation status loop waiting for a signal.

