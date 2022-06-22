# circleci-cicd-pipeline
Circleci Pipeline to deploy a web application

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