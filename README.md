# circleci-cicd-pipeline
Circleci Pipeline to deploy a web application

# Build

![Build screenshot1-2](/docs/screenshots/SCREENSHOT01-2.png)

![Build screenshot1-3](/docs/screenshots/SCREENSHOT01-3.png)

# Test

![Test screenshot2](/docs/screenshots/SCREENSHOT02-1.png)

![Test screenshot2 Fix](/docs/screenshots/SCREENSHOT02-2.png)


# Audit

![Audit screenshot3](/docs/screenshots/SCREENSHOT03.png)

![Audit screenshot3 frontend](/docs/screenshots/SCREENSHOT03_frontend.png)

![Audit screenshot3 Jira](/docs/screenshots/SCREENSHOT03_fixed_jira.png)

# Notification Setup

![Jira screenshot1](/docs/screenshots/SCREENSHOT02_jira1.png)


![Jira screenshot2](/docs/screenshots/SCREENSHOT02_jira2.png)


# JIRA integration with Circleci

- Install Circleci App in JIRA. Click on Get started and copy Token to
- Circleci : Project settings > Jira Integration
- Circleci: Personal settings > Create Access Token and copy Token to
- Circleci : Project settings > Environment Variables > CIRCLE_TOKEN

orbs:

  jira: circleci/jira@1.3.1
  
# Slack integration with Circleci

    orbs: 

      slack: circleci/slack@4.10.1

- To obtain a Bot Auth follow steps in [Connecting Circleci to Slack](https://github.com/CircleCI-Public/slack-orb/wiki/Setup and Copy to 
- Circleci : Project settings > Environment Variables > SLACK_ACCESS_TOKEN
- Circleci : Project settings > Environment Variables > SLACK_DEFAULT_CHANNEL