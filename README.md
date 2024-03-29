# circleci-cicd-pipeline [![CircleCI](https://dl.circleci.com/status-badge/img/gh/oliviermbida/circleci-cicd-pipeline/tree/master.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/oliviermbida/circleci-cicd-pipeline/tree/master)
Circleci Pipeline to deploy a web application an implementation of :

- Utilizing Deployment Strategies to design and build CI/CD pipelines that support Continuous Delivery processes.

- Utilizing a configuration management tool to accomplish deployment to cloud-based servers.

- Surface critical server errors for diagnosis using centralized structured logging.

![Solution Architecture](/docs/screenshots/circleci_cicd_pipeline.png)

# Solution overview

. Circleci CI/CD Pipeline

. Source control GIT Workflow

. AWS CloudFormation for Infrastructure As Code

. Ansible for Configuration As Code

. Docker builds

. Docker Cloud Test servers e.g SonarCloud

. JIRA issue integration and Project management

. Slack issue notification

. Monitoring: Prometheus Alerts with Slack notification

# Security

. Multi IAM users Circleci pipeline job step execution i.e IAM users such as Admin(security), Database Admin , DevOps team and web developers each have different priviledges in setting up infrastructure and configuration. An example of how different teams have to collaborate.

. Use of restricted context to store github or bitbucket secrets in Circleci.

. Use of AWS secret manager and KMS to store sensitive details such as database username and password. 
These details can only be shared with the credentials of an authorize IAM user such as Admin(security) or Database Admin.
Secrets can be rotated without the need of manually deleting and adding new environment variables in Circleci context.

# Features

. Stack status sync in Circleci pipeline when deploying infrastructure to AWS

. Git Push command available in Circleci job step to commit for example audit fixes back to master

. Optionally create a cloudfront distribution. Used pipeline paramaters for existing distribution for example in setting up blue environment. 

. Can setup AWS infrastructure in isolated job and re-use it to run deployment jobs saving time.

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

# Configuration Phase

When adding your ansible roles and tasks you can also check your commands before adding to the workflow. Just add a host you want to test those commands in your inventory file e.g

    [webserver]
    web ansible_host=$EC2_HOST_IP ansible_connection=ssh  ansible_user=$EC2_USER ansible_ssh_private_key_file=ec2_key_pair.pem

On linux make sure you set permissions for your ec2_key_pair.pem otherwise this will be rejected by aws.

Now run your play with the debug option to catch any errors. For example testing configure-server

    ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook -i inventory.ini configure-server.yml


![Screenshot ansible test](/docs/screenshots/SCREENSHOT06_ansible.png)

You can ssh to the host and check the configuration. In this case configure-server was suppose to install pm2 and it did.

    ssh -i ec2_key_pair.pem EC2_USER@EC2_HOST_IP

![Screenshot pm2](/docs/screenshots/SCREENSHOT06_pm2.png)

Once tested they be added to the configuration stage in the pipeline as seen in this [screenshot](/docs/screenshots/SCREENSHOT06_config.png)


# Migrations

I will use the same approach i.e start by checking that everything is working locally before adding to the pipeline.

The migration strategy I will use will be to create a tunnel using the backend as a bastion to get to the postgres database which in most cases for security will not be in public subnet and therefore will not have public access.

Before running the ssh tunnel below make sure your backend only allows authorized IP addresses in the Cidr block.

        SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: authorized_ips

        ssh -4 -i your_ec2_key_pair -f -N -L 5532:$RDS_HOST:5432 $EC2_USER@$EC2_HOST

If you tag your EC2 instance with Name=my_ec2, you can filter as such:

        EC2_HOST=$(aws --output text --query 'Reservations[*].Instances[*].PublicIpAddress' \
            ec2 describe-instances --filters Name='tag:Name',Values='my_ec2')

And the RDS postgres with identifier my_db:

        RDS_HOST=$(aws rds describe-db-instances \
            --db-instance-identifier my_db \
            --output text --query "DBInstances[*].Endpoint.Address")

This will retrieve a DNS name that resolves to a private IP address or to a public IP address if you set it as Publicly Accessible.

The -4 in the command is to force IPv4 protocol because the AWS RDS connection defaults to IPv6 for some reason.

Hang on I hear you say why copy your_ec2_key_pair into a Circleci pipeline, not really secure.
You can store it as a secret in AWS secrets manager and do this:

        aws ssm get-parameter \
            --name /aws/reference/secretsmanager/your_ec2_key_pair \
            --with-decryption --output text --query "Parameter.Value" > "$HOME/.ssh/id_ed25519"

        chmod 0700 "$HOME/.ssh/id_ed25519"

When you run the ssh command it automatically authenticates with those details but don't forget to cleanup the id_ed25519 file when done or id_rsa if your key is such.

One last issue setting up this tunnel is the known hosts. You will have to add the fingerprint of the EC2_HOST in $HOME/.ssh/known_hosts.

You can get the fingerprint of the EC2_HOST at creation by monitoring the EC2 console output:

        aws --output text ec2 get-console-output --instance-id $EC2_HOST_ID >> output.txt

where :

        EC2_HOST_ID=$(aws --output text --query 'Reservations[*].Instances[*].InstanceId' \
        ec2 describe-instances --filters Name='tag:Name',Values='my_ec2') 

You could probably filter the output with:

        sed -n '/-----BEGIN SSH HOST KEY FINGERPRINTS-----/,/-----END SSH HOST KEY FINGERPRINTS-----/p' output.txt >> EC2_HOST_FINGERPRINT

If you've already tested the connection and know EC2_HOST fingerprint then you may run this ssh command instead:

        ssh -4 -i $HOME/.ssh/id_ed25519 -o StrictHostKeyChecking=no -f -N -L 5532:$RDS_HOST:$RDS_PORT $EC2_USER@$EC2_HOST 

This will automatically add the EC2_HOST to the $HOME/.ssh/known_hosts without a prompt.

When you run the command above (SSH tunneling), you configure the following settings:

    - Local connections to LOCALHOST: 5532 forwarded to remote address RDS_HOST:5432
    - Local forwarding listening on 127.0.0.1 port 5532.
    - channel 0: new [port listener]
    - Local forwarding listening on ::1 port 5532.

After creating the tunnel you can test the connection to your_postgres_database with your_postgres_username:

        psql -hlocalhost -Uyour_postgres_username -p5532 -d your_postgres_database

And finally getting back to the pipeline,for the backend configuration you will therefore set TYPEORM_HOST=localhost and TYPEORM_PORT=5532. This will just connect as if it was localhost and perform your migrations or revert migrations.

# Migration tests

In this screenshot there are 3 tests done. Before migrations, after migrations and revert migrations.
As you can see there are no tables before migrations and after revert migrations phase.

![Screenshot pm2](/docs/screenshots/MIGRATIONS02.png)

[Migrations report](/docs/reports/migrations.txt)

To implement this in the pipeline I will define my own test function.

1. I need to know what is it I will be testing:

        ls $TYPEORM_MIGRATIONS_DIR | sed -e s/-/''/ -e s/.ts/''/ -e 's/\([0-9]*\) *\(.*\)/\2\1/' -e 's/^/Migration /g' -e 's/$/ has been executed successfully./g' >> MIGRATIONS_TESTS

The output of this command is simply this:

        Migration AddOrders1549375960026 has been executed successfully.
        Migration FixProductIdTable1549398619849 has been executed successfully.
        Migration AddEmployee1555722583168 has been executed successfully.

I hear you say, all that just for this output? This is because these are the only migrations present in the TYPEORM_MIGRATIONS_DIR. If there were 100 migrations the output of the command will return them.
Yes, the above command looks for migration files in the TYPEORM_MIGRATIONS_DIR and format it in the form present in the migrations report output of  'npm run migrations'.

2. It is easy to count those above but if there are many:

        NUMBER_OF_TESTS=$(grep -c ^ MIGRATIONS_TESTS)

3. Now I can define my test function:

        GREEN='\033[0;32m'       
        RED='\033[0;31m'        
        NC='\033[0m' 

        test_migrations () {

        PARSE_RESULT=$(grep -oh "$1" $2 >/dev/null; echo $?)

        case $PARSE_RESULT in
        0)
        printf "TEST: ${GREEN}PASSED${NC}\n"
        ;;
        *)
        printf "TEST: ${RED}FAILED${NC}\n"
        # trigger revert migrations
        exit 1
        ;;           
        esac

        }

4. I can now go through every expected expression in the migrations report:

        TEST_PASSED=$(sed -n 1p /tmp/MIGRATIONS_TESTS)

In the output above this will retrieve the first:

        Migration AddOrders1549375960026 has been executed successfully.

And so on sed -n 2p...3p

        n=$(seq $NUMBER_OF_TESTS)
        for i in $n
        do
        # define expected expression in migrations report
        # e.g "Migration AddOrders1549375960026 has been executed successfully"
        TEST_PASSED=$(sed -n "$i"p $MIGRATIONS_TESTS)
        echo $TEST_PASSED
        # parse migration report and assert expected expression
        test_migrations "$TEST_PASSED" $MIGRATIONS_REPORT
        done

5. With our expected expression I can now parse the migration report and assert if found:

        test_migrations "$TEST_PASSED" $MIGRATIONS_REPORT

A failed test will exit 1 and since the Revert Migrations step is on condition on_fail in the Circleci pipeline this will be triggered.

Obviously this is one way of testing if migrations were performed by parsing the migrations report but you can also go direct and query the database either manually as shown in the screenshot if it is a small migration or with queries to the database to see if they exist.

Note: The command above assumes that TYPEORM_MIGRATIONS_DIR contains migrations which are not present in the postgres database. To remove this assumption a parse of other expected expressions of existing migrations is necessary
such as :

        2 migrations are already loaded in the database.
        3 migrations were found in the source code.
        1 migrations are new migrations that needs to be executed.

And refine the MIGRATIONS_TESTS to take into account the above details.

# Revert migrations

I can apply the same technique to check on migrations which have been reverted.
The expected expresssion in the report will be of the form:

        Migration AddEmployee1555722583168 has been reverted successfully.


![Revert Migrations](/docs/screenshots/SCREENSHOT07.png)


# Deploy Frontend

Since the frontend is an S3 bucket there is a very simply command which will copy or sync the build artifacts:

        aws s3 sync \
        ./frontend/dist s3://$S3_BUCKET_NAME/build-${CIRCLE_WORKFLOW_ID:0:7}/--delete \
        --acl public-read \
        --cache-control "max-age=86400" 

On failure:

            aws s3 rm s3://$S3_BUCKET_NAME/build-${CIRCLE_WORKFLOW_ID:0:7} --recursive 

# Deploy Backend

SSH into backend EC2 instance and maually check that the PM2 service is running the App

![Revert Migrations](/docs/screenshots/DEPLOYBACKENDPM2.png)

# Smoke Test

![Frontend Test](/docs/screenshots/FRONTEND_SMOKE_TEST.png)

![Backend Test](/docs/screenshots/BACKEND_SMOKE_TEST.png)

And in case of a failed somke test, rollback deployment

![Smoke test Rollback](/docs/screenshots/SMOKETEST_ROLLBACK.png)

# Manual Approval

![Manual Approval](/docs/screenshots/APPROVAL01.png)

![Manual Approval](/docs/screenshots/APPROVAL02.png)

![Slack Approval](/docs/screenshots/APPROVAL03.png)

# Update

There are two scenarios to update the cloudfront distribution:

1. If you are running a Blue/Green deployment, you may have a running cloudfront distribution serving your blue environment.
In this case you don't need the workflow to create another one, you simply set the pipeline parameters to update your current cloudfront distribution details using your Distribution ID and the Origin ID.

2. Here the workflow creates a Cloudfront distribution during the Deploy Infrastructure job and you can then query the stack outputs to get the cloudfront distribution details.

![Stack Outputs](/docs/screenshots/STACK_OUTPUTS.png)

        # get distribution details from stack outputs

        aws --query "Stacks[].Outputs[?OutputKey=='DistributionID'].OutputValue" \
        --output text \
        cloudformation describe-stacks --stack-name <<pipeline.parameters.environment>> \
        > DISTRIBUTION_ID

        aws --query "Stacks[].Outputs[?OutputKey=='OriginID'].OutputValue" \
        --output text \
        cloudformation describe-stacks --stack-name <<pipeline.parameters.environment>> \
        > CLOUDFRONT_ORIGIN_ID

The update I will perform on the Cloudfront distribution is to change the OriginPath to the latest deployment folder S3_LATEST_BUILD_FOLDER of the frontend. 
Get the current configuration 'cloudfront.json' of the distribution and update the OriginPath as such:

        S3_LATEST_BUILD_FOLDER=build-${CIRCLE_WORKFLOW_ID:0:7}

        jq ".Distribution.DistributionConfig                    |
        (select(.Origins.Items[][\"Id\"] == \"$CLOUDFRONT_ORIGIN_ID\")  |
        .Origins.Items[].OriginPath) = \"/$S3_LATEST_BUILD_FOLDER\" " ./cloudfront.json > cloudfront_update.json

And then apply it to the cloudfront distribution:

        aws cloudfront update-distribution --id $DISTRIBUTION_ID --if-match $ETAG \
        --distribution-config file://./cloudfront_update.json > /dev/null 

/dev/null is just to surpress the output of aws cli which can cause an error in Circleci even when the update is successful.
I think the issue is to do with 'less' which you can install if you don't want to surpress the output.

This approach of updating the latest deployment folder has the advantage of not pulling down stacks or deleted any infrastructure but just a folder which is less time consuming that creating new stacks.

# Cleanup

Once the latest build is deployed, the old build files are removed.

![Cleanup old workflow](/docs/screenshots/SCREENSHOT09.png)

# Monitoring - Prometheus

Using ansible:

Setup prometheus server in an EC2 instance.

![Prometheus server](/docs/screenshots/PROMETHEUS_SERVER.png)

Setup prometheus node exporter in the backend instance.

![Prometheus node](/docs/screenshots/PROMETHEUS_NODE.png)

Now let the server discover the node:

        prometheus_scrape_configs:
        - job_name: "ec2_node"
        # metrics_path: "{{ prometheus_metrics_path }}"
        ec2_sd_configs:
        - region: "{{ lookup('ansible.builtin.env', 'AWS_DEFAULT_REGION') }}"
                access_key: "{{ lookup('ansible.builtin.env', 'AWS_ACCESS_KEY_ID') }}"
                secret_key: "{{ lookup('ansible.builtin.env', 'AWS_SECRET_ACCESS_KEY') }}"
                port: 9100
                filters:
                - name: tag:Name
                values:
                - "backend-{{ resource_id }}"
        relabel_configs:
        - source_labels: [__meta_ec2_public_dns_name]
                replacement: '${1}:9100'
                target_label: __address__
        - source_labels: [__meta_ec2_tag_Name]
                target_label: instance

![Prometheus discovery](/docs/screenshots/URL05_SCREENSHOT.png)

And get the metrics

![Prometheus node metrics](/docs/screenshots/SCREENSHOT11.png)

# Teardown

This teardowns the whole aws infrastructure:

        aws cloudformation delete-stack --stack-name <<pipeline.parameters.environment>>

# Filter Jobs by branch

![Filters](/docs/screenshots/SCREENSHOT10_1.png)

![Filters deployment](/docs/screenshots/SCREENSHOT_DEPLOYMENTS_APPROVAL.png)


# Troubleshooting by skipping jobs

Especially when you have already deployed infrastructure and you don't really want to pull down the whole pipeline.
In my case below, I had some issues with the migration step in the pipeline because I had tested ssh tunneling earlier.
I wrote this command which is using the circleci-agent:

        check_job:
            description: Stop job if false  
            parameters:
                start_job:
                    type: boolean
                    default: true        
            steps: 
                - when:
                    condition: 
                        not: << parameters.start_job >>
                    steps:
                        - run: circleci-agent step halt   

I just had to switch it to true in any job I wanted to run and this meant I could focus on the issue with the migration step as seen in the screenshot.

 ![skipping jobs](/docs/screenshots/Troubleshooting_by_skiping_jobs.png)

You can use this skip job functionality to fix the audits found in the scan-frontend and scan-backend jobs.
I will use it to commit the audits to this project in github.
Here is how the security issues are reported by github, please note the 168 vulnerabilities figure :

![Github security alerts](/docs/screenshots/security_github.png)

Now screenshot after I ran the scan-frontend job with the commit_to_github command.
Please note all other jobs are disabled with the check_job command above.
You can see down to 82 vulnerabilities detected by github.
Please also note that the commit did not run the Circleci pipeline.

![Github security alerts frontend fix](/docs/screenshots/security_github_frontend_fix.png)

![Github security alerts audit](/docs/screenshots/security_audit_frontend.png)

I did the same with the backend and it is now down to 22 vulnerabilities.
So more to do to clean it up using other security tools in the workflow.

![Github security alerts backend fix](/docs/screenshots/security_github_backend_fix.png)

Please note that commiting these audit fixes will have a major impact on the App. For example if developers have injected some dependencies which have been found to be a security vulnerability and these audit fixes removed them then you will find that builds start to fail.

# Troubleshoot with ssh

![Run jon with ssh ](/docs/screenshots/TROUBLESHOOT_SSH.png)
