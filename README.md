<h1 align="center">Terraform AWS Linux Server with Monitoring</h1>

<p align="center">
A beginner-friendly Infrastructure as Code (IaC) project. With a few commands, Terraform builds a small, monitored Linux web server on Amazon Web Services (AWS), and one more command removes everything again.
</p>

<p>
If you have never used AWS or Terraform before, start at the top and read in order. Every term is explained in plain words.
</p>

<h2>Contents</h2>

<ol>
  <li><a href="#what-is-this-project">What is this project?</a></li>
  <li><a href="#who-is-this-for">Who is this for and what will you learn?</a></li>
  <li><a href="#what-gets-created">What gets created</a></li>
  <li><a href="#key-concepts">Key concepts in simple words</a></li>
  <li><a href="#tech-stack">Tech stack</a></li>
  <li><a href="#prerequisites">Prerequisites checklist</a></li>
  <li><a href="#install-tools">Install the tools</a></li>
  <li><a href="#aws-account-setup">Set up your AWS account</a></li>
  <li><a href="#project-structure">Project structure</a></li>
  <li><a href="#quick-start">Quick start for experienced users</a></li>
  <li><a href="#cost-and-safety">Cost and safety</a></li>
  <li><a href="#next-step">Next: the step-by-step guide</a></li>
</ol>

<hr>

<h2 id="what-is-this-project">1. What is this project?</h2>

<p>
Normally, to run a website on a server in the cloud, a person logs in to the AWS web console and clicks through dozens of screens: create a network, create a firewall, create a server, set up alerts. It is slow, easy to get wrong, and hard to repeat.
</p>

<p>
This project does the same thing with <b>code</b>. The files ending in <code>.tf</code> describe the infrastructure you want. When you run <code>terraform apply</code>, Terraform reads them and creates everything in AWS automatically. When you run <code>terraform destroy</code>, it deletes it all.
</p>

<p>The finished result is:</p>

<ul>
  <li>A <b>Linux server</b> (Amazon Linux 2023) running the <b>Nginx</b> web server.</li>
  <li>A <b>web page</b> you can open in a browser to prove it works.</li>
  <li>A <b>health check</b> that restarts Nginx if it stops responding.</li>
  <li><b>Monitoring and email alerts</b>: if the server's CPU stays high, or the server itself fails, AWS emails you.</li>
  <li><b>No SSH keys and no open SSH port.</b> You log in to the server securely through AWS Systems Manager (SSM) instead.</li>
  <li>A <b>CI pipeline</b> (GitHub Actions) that automatically checks the Terraform code on every pull request.</li>
</ul>

<h2 id="who-is-this-for">2. Who is this for and what will you learn?</h2>

<p>
<b>For:</b> students, interns, and junior engineers who want a small but realistic DevOps project. No prior AWS or Terraform knowledge is needed. You should be comfortable typing commands in a terminal.
</p>

<p><b>You will learn:</b></p>

<ul>
  <li>How to write and run Terraform (init, plan, apply, destroy)</li>
  <li>How an AWS network is built: VPC, subnet, internet gateway, route table, security group</li>
  <li>How to launch and configure a Linux server on boot with a Bash script</li>
  <li>How to give a server permissions safely with IAM roles</li>
  <li>How to set up CloudWatch alarms and SNS email notifications</li>
  <li>Why remote state in S3 matters and how state locking works</li>
  <li>How a basic CI pipeline validates infrastructure code with GitHub Actions</li>
  <li>How to clean up cloud resources so you do not pay for what you do not use</li>
</ul>

<h2 id="what-gets-created">3. What gets created</h2>

<pre>
Internet
   |
   v
Internet Gateway
   |
   v
Public subnet (inside your own VPC)
   |
   v
EC2 Linux server  (Nginx + health check script)
   |
   +--> CloudWatch alarms --> SNS topic --> your email
</pre>

<table>
  <thead>
    <tr>
      <th>AWS resource</th>
      <th>Terraform name</th>
      <th>What it is for</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>VPC</td><td><code>aws_vpc.main</code></td><td>Your own private network inside AWS</td></tr>
    <tr><td>Internet gateway</td><td><code>aws_internet_gateway.main</code></td><td>The door between your VPC and the internet</td></tr>
    <tr><td>Public subnet</td><td><code>aws_subnet.public</code></td><td>A section of the VPC where the server lives</td></tr>
    <tr><td>Route table and association</td><td><code>aws_route_table.public</code></td><td>Tells the subnet to send internet traffic through the gateway</td></tr>
    <tr><td>Security group</td><td><code>aws_security_group.web</code></td><td>A firewall: allows web traffic (port 80) in, nothing else</td></tr>
    <tr><td>IAM role, policy attachment, instance profile</td><td><code>aws_iam_role.ec2</code> and related</td><td>Lets the server be managed through SSM without passwords or keys</td></tr>
    <tr><td>EC2 instance</td><td><code>aws_instance.web</code></td><td>The Linux server (t3.micro, Amazon Linux 2023)</td></tr>
    <tr><td>SNS topic and email subscription</td><td><code>aws_sns_topic.alerts</code></td><td>The channel that delivers alarm emails</td></tr>
    <tr><td>CloudWatch alarm: high CPU</td><td><code>aws_cloudwatch_metric_alarm.cpu_high</code></td><td>Fires when average CPU stays above the threshold for 10 minutes</td></tr>
    <tr><td>CloudWatch alarm: status check</td><td><code>aws_cloudwatch_metric_alarm.status_check_failed</code></td><td>Fires when AWS detects the server or its host is unhealthy</td></tr>
    <tr><td>S3 bucket (created by a script)</td><td>not in Terraform</td><td>Stores the Terraform state file safely</td></tr>
  </tbody>
</table>

<h2 id="key-concepts">4. Key concepts in simple words</h2>

<table>
  <thead>
    <tr>
      <th>Term</th>
      <th>Plain-English meaning</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><b>Cloud / AWS</b></td><td>Renting computers, storage and networks from Amazon over the internet instead of buying your own.</td></tr>
    <tr><td><b>Region</b></td><td>A geographic area where AWS has data centres, for example <code>ap-south-1</code> is Mumbai. You choose where your resources live.</td></tr>
    <tr><td><b>EC2</b></td><td>AWS's service for virtual servers. An "instance" is one server.</td></tr>
    <tr><td><b>AMI</b></td><td>The template an instance starts from (the operating system image). We use the latest Amazon Linux 2023.</td></tr>
    <tr><td><b>VPC</b></td><td>A virtual private network that belongs only to you.</td></tr>
    <tr><td><b>Subnet</b></td><td>A smaller slice of a VPC. A <i>public</i> subnet can reach the internet.</td></tr>
    <tr><td><b>Internet gateway / route table</b></td><td>The gateway connects the VPC to the internet. The route table is the signpost that tells traffic to use it.</td></tr>
    <tr><td><b>Security group</b></td><td>A virtual firewall attached to the server. It lists which traffic is allowed in and out.</td></tr>
    <tr><td><b>IAM</b></td><td>AWS's permission system. It decides who or what can do what.</td></tr>
    <tr><td><b>IAM role / instance profile</b></td><td>A set of permissions that a <i>server</i> can use, so you never store passwords or keys on it.</td></tr>
    <tr><td><b>Terraform</b></td><td>A tool that creates cloud resources from code files.</td></tr>
    <tr><td><b>Infrastructure as Code (IaC)</b></td><td>Describing infrastructure in files that you can version, review and repeat, instead of clicking in a console.</td></tr>
    <tr><td><b>Provider</b></td><td>The Terraform plugin that knows how to talk to a service. Here it is the AWS provider.</td></tr>
    <tr><td><b>State file</b></td><td>Terraform's notebook of what it has created. Without it, Terraform cannot know what to change or delete.</td></tr>
    <tr><td><b>Remote state / locking</b></td><td>Keeping the state file in S3 instead of your laptop, and preventing two people from changing it at the same time.</td></tr>
    <tr><td><b>S3</b></td><td>AWS's file storage service. We use one bucket for the state file.</td></tr>
    <tr><td><b>user_data</b></td><td>A script that runs once when the server first boots. Ours installs and configures Nginx.</td></tr>
    <tr><td><b>Nginx</b></td><td>A popular web server program.</td></tr>
    <tr><td><b>Bash</b></td><td>The scripting language used in <code>user_data.sh</code> and the helper script.</td></tr>
    <tr><td><b>cron</b></td><td>The Linux scheduler. We use it to run the health check every 5 minutes.</td></tr>
    <tr><td><b>CloudWatch</b></td><td>AWS's monitoring service. It collects metrics such as CPU and raises alarms.</td></tr>
    <tr><td><b>SNS</b></td><td>AWS's notification service. It delivers the alarm to your email.</td></tr>
    <tr><td><b>SSM Session Manager</b></td><td>A secure way to open a shell on the server through AWS, without SSH keys or open ports.</td></tr>
    <tr><td><b>IMDSv2</b></td><td>The safer version of the server's metadata service. We require it so attackers cannot easily steal credentials.</td></tr>
    <tr><td><b>CI/CD</b></td><td>Automatically testing and delivering changes. Here, CI checks the Terraform code every time you open a pull request.</td></tr>
    <tr><td><b>GitHub Actions</b></td><td>GitHub's built-in automation that runs the CI checks.</td></tr>
  </tbody>
</table>

<h2 id="tech-stack">5. Tech stack</h2>

<table>
  <thead>
    <tr>
      <th>Technology</th>
      <th>Version</th>
      <th>Why it is used</th>
      <th>Required?</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Terraform</td><td>1.10 or newer</td><td>Creates and destroys the AWS resources</td><td>Yes</td></tr>
    <tr><td>AWS provider for Terraform</td><td>5.x (downloaded automatically)</td><td>Lets Terraform talk to AWS</td><td>Yes (automatic)</td></tr>
    <tr><td>AWS account</td><td>Free tier or credits</td><td>Where everything runs</td><td>Yes</td></tr>
    <tr><td>AWS CLI</td><td>v2</td><td>Logs you in, creates the state bucket, opens SSM sessions</td><td>Yes</td></tr>
    <tr><td>Git</td><td>Any recent version</td><td>Version control, pushing to GitHub</td><td>Yes</td></tr>
    <tr><td>Bash</td><td>Built in on Linux and macOS; use Git Bash or WSL on Windows</td><td>Runs the helper script and the boot script</td><td>Yes</td></tr>
    <tr><td>Amazon Linux 2023</td><td>Latest (resolved automatically)</td><td>The server operating system</td><td>Yes (automatic)</td></tr>
    <tr><td>Nginx</td><td>From the Amazon Linux repository</td><td>The web server</td><td>Yes (automatic)</td></tr>
    <tr><td>AWS Session Manager plugin</td><td>Latest</td><td>Needed only for <code>aws ssm start-session</code> from your terminal</td><td>Optional</td></tr>
    <tr><td>GitHub account and GitHub Actions</td><td>n/a</td><td>Runs CI checks on pull requests</td><td>Optional</td></tr>
    <tr><td>Text editor such as VS Code</td><td>Any</td><td>Viewing and editing the files</td><td>Recommended</td></tr>
  </tbody>
</table>

<h2 id="prerequisites">6. Prerequisites checklist</h2>

<p>Before you start, make sure you have:</p>

<p><b>Knowledge</b></p>
<ul>
  <li>&#9744; Comfort opening a terminal and running commands</li>
  <li>&#9744; A basic idea of what a server and a website are (everything else is explained here)</li>
</ul>

<p><b>Accounts</b></p>
<ul>
  <li>&#9744; An AWS account (a credit or debit card is required to sign up)</li>
  <li>&#9744; An email address you can check (alarm emails are sent here)</li>
  <li>&#9744; A GitHub account (only needed to publish the project and use CI)</li>
</ul>

<p><b>Software</b> (installed in the next section)</p>
<ul>
  <li>&#9744; Git</li>
  <li>&#9744; Terraform 1.10 or newer</li>
  <li>&#9744; AWS CLI v2</li>
  <li>&#9744; Session Manager plugin (optional)</li>
</ul>

<p><b>Computer</b></p>
<ul>
  <li>&#9744; Windows 10/11, macOS, or Linux, with an internet connection</li>
</ul>

<h2 id="install-tools">7. Install the tools</h2>

<p>Pick the section for your operating system. After installing, close and reopen your terminal.</p>

<h3>macOS (using Homebrew)</h3>

<pre><code>brew install git awscli
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew install --cask session-manager-plugin   # optional</code></pre>

<h3>Ubuntu / Debian Linux</h3>

<pre><code># Git and helper tools
sudo apt update &amp;&amp; sudo apt install -y git unzip curl gnupg lsb-release

# Terraform (official HashiCorp repository)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update &amp;&amp; sudo apt install -y terraform

# AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip
sudo ./aws/install</code></pre>

<p>
The Session Manager plugin is optional. Install it by searching the AWS documentation for "Install the Session Manager plugin for the AWS CLI".
</p>

<h3>Windows (PowerShell)</h3>

<pre><code>winget install Git.Git
winget install Hashicorp.Terraform
winget install Amazon.AWSCLI</code></pre>

<p>
Run the project's Bash scripts from <b>Git Bash</b> (installed with Git) or from <b>WSL</b> (Windows Subsystem for Linux). WSL with Ubuntu is the smoothest option: open it and follow the Ubuntu steps above.
</p>

<h3>Check that everything works</h3>

<pre><code>git --version
terraform version      # must show v1.10.0 or newer
aws --version          # must show aws-cli/2.x</code></pre>

<p>
If <code>terraform version</code> shows something older than 1.10, upgrade it. The S3 state locking used in this project needs 1.10 or newer.
</p>

<h2 id="aws-account-setup">8. Set up your AWS account</h2>

<h3>8.1 Create the account and protect it</h3>

<ol>
  <li>Go to <a href="https://aws.amazon.com">aws.amazon.com</a> and choose <b>Create an AWS account</b>.</li>
  <li>Sign in as the <b>root user</b> (the email you signed up with).</li>
  <li>Turn on <b>multi-factor authentication (MFA)</b> for the root user: Account menu, Security credentials, Assign MFA device.</li>
  <li><b>Never create access keys for the root user, and never use it for daily work.</b></li>
</ol>

<h3>8.2 Create a user for Terraform</h3>

<ol>
  <li>Open the <b>IAM</b> service, then <b>Users</b>, then <b>Create user</b>.</li>
  <li>Name it, for example <code>terraform-learner</code>.</li>
  <li>Attach permissions. This project creates networks, servers, alarms and an IAM role, so the user needs broad rights. For a personal learning account, attach <b>AdministratorAccess</b>. In a company account, ask your administrator for a limited role that allows EC2, VPC, IAM, CloudWatch, SNS and S3.</li>
  <li>Open the user, then <b>Security credentials</b>, then <b>Create access key</b>, and choose <b>Command Line Interface (CLI)</b>.</li>
  <li>Copy the <b>Access key ID</b> and <b>Secret access key</b> somewhere safe. The secret is shown only once.</li>
</ol>

<blockquote>
<b>Warning:</b> Access keys are passwords. Never put them in the project files, never commit them to GitHub, and never share them in chat or screenshots. If a key leaks, delete it in IAM immediately.
</blockquote>

<h3>8.3 Connect the AWS CLI to your account</h3>

<pre><code>aws configure</code></pre>

<p>Enter, when asked:</p>

<table>
  <thead>
    <tr>
      <th>Prompt</th>
      <th>What to enter</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>AWS Access Key ID</td><td>the key ID from step 8.2</td></tr>
    <tr><td>AWS Secret Access Key</td><td>the secret from step 8.2</td></tr>
    <tr><td>Default region name</td><td><code>ap-south-1</code> (Mumbai) or the region closest to you</td></tr>
    <tr><td>Default output format</td><td><code>json</code></td></tr>
  </tbody>
</table>

<p>Test it:</p>

<pre><code>aws sts get-caller-identity</code></pre>

<p>
You should see your account number and user name. If you see an error, the keys or region were entered incorrectly. Run <code>aws configure</code> again.
</p>

<h3>8.4 Set a budget alert (strongly recommended)</h3>

<ol>
  <li>Open <b>Billing and Cost Management</b>, then <b>Budgets</b>, then <b>Create budget</b>.</li>
  <li>Choose a <b>monthly cost budget</b> of a small amount, for example 5 USD.</li>
  <li>Add your email for alerts.</li>
</ol>

<p>This protects you if you forget to destroy something.</p>

<h2 id="project-structure">9. Project structure</h2>

<pre>
terraform-aws-linux-monitoring/
|-- README.md                      concepts and setup
|-- docs/
|   `-- DEPLOYMENT_GUIDE.md        step-by-step deploy, verify, troubleshoot, clean up
|-- versions.tf                    Terraform and provider versions, AWS region setup, default tags
|-- backend.tf                     Tells Terraform to keep its state file in S3
|-- variables.tf                   The settings you can change (region, instance size, email, ...)
|-- main.tf                        The infrastructure itself: network, firewall, server, alarms
|-- outputs.tf                     Values printed after apply (website URL, instance ID, ...)
|-- user_data.sh                   Bash script the server runs on first boot (installs Nginx, health check)
|-- terraform.tfvars.example       Template for your own settings (copy to terraform.tfvars)
|-- backend.hcl.example            Template for the state bucket settings (copy to backend.hcl)
|-- bootstrap/
|   `-- create_state_bucket.sh     Creates the S3 bucket that stores the state file
|-- .github/
|   `-- workflows/
|       `-- terraform.yml          GitHub Actions pipeline: format check, validate, optional plan
`-- .gitignore                     Keeps secrets and generated files out of Git
</pre>

<p>What each key file does:</p>

<ul>
  <li><b><code>main.tf</code></b> is the heart of the project. Read it top to bottom: networking, firewall, IAM, server, then monitoring.</li>
  <li><b><code>variables.tf</code></b> lists the inputs. Only <code>alert_email</code> has no default, so you must provide it.</li>
  <li><b><code>user_data.sh</code></b> runs as root the first time the server boots. It updates the system, installs Nginx and cron, writes the web page, and creates the health check that runs every 5 minutes.</li>
  <li><b><code>terraform.tfvars</code></b> (you create it from the example) holds <i>your</i> values. It is ignored by Git.</li>
  <li><b><code>backend.hcl</code></b> (you create it from the example) holds your state bucket name. It is ignored by Git.</li>
  <li><b><code>.terraform.lock.hcl</code></b> (created by <code>terraform init</code>) pins the provider version. Do commit this one.</li>
</ul>

<h2 id="quick-start">10. Quick start for experienced users</h2>

<p>If you already know Terraform and AWS, this is the whole flow:</p>

<pre><code>terraform fmt -recursive
./bootstrap/create_state_bucket.sh &lt;unique-bucket-name&gt; ap-south-1
cp backend.hcl.example backend.hcl            # set the bucket name
cp terraform.tfvars.example terraform.tfvars  # set alert_email
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
terraform output website_url
terraform destroy                             # when you are done</code></pre>

<h2 id="cost-and-safety">11. Cost and safety</h2>

<ul>
  <li><b>Cost:</b> a t3.micro server for a few hours is very cheap, and may be covered by the AWS free tier or new-account credits. Free tier terms change, so check the current rules on the AWS Free Tier page. The VPC, security group, IAM role, SNS topic and alarms cost little or nothing for a short test.</li>
  <li><b>Always destroy when finished.</b> Run <code>terraform destroy</code> so nothing keeps running and billing you. Also delete the state bucket if you no longer need it.</li>
  <li><b>The web server is public on purpose.</b> Port 80 is open to the whole internet so you can see the page. The page contains no secrets. Do not put private data on this server.</li>
  <li><b>There is no SSH port.</b> You reach the server only through SSM, which is logged and controlled by IAM.</li>
  <li><b>Never commit</b> <code>terraform.tfvars</code>, <code>backend.hcl</code>, state files, or AWS keys. The <code>.gitignore</code> already blocks them, but always check <code>git status</code> before pushing.</li>
</ul>

<h2 id="next-step">12. Next: the step-by-step guide</h2>

<p>
You now know what the project is, what it needs, and how to prepare your computer and AWS account.
</p>

<h1 align="center">Deployment Guide </h1>

<p align="center">
Step-by-step instructions to deploy, test, publish and clean up the Terraform AWS Linux Server project.
</p>

<h2>Contents</h2>

<ol>
  <li><a href="#overview">Overview of the steps</a></li>
  <li><a href="#step-1">Step 1: Get the project and open it in a terminal</a></li>
  <li><a href="#step-2">Step 2: Format the code</a></li>
  <li><a href="#step-3">Step 3: Create the state bucket</a></li>
  <li><a href="#step-4">Step 4: Create your settings files</a></li>
  <li><a href="#step-5">Step 5: Initialise Terraform</a></li>
  <li><a href="#step-6">Step 6: Plan</a></li>
  <li><a href="#step-7">Step 7: Apply</a></li>
  <li><a href="#step-8">Step 8: Confirm the email subscription</a></li>
  <li><a href="#step-9">Step 9: Open the website</a></li>
  <li><a href="#step-10">Step 10: Log in to the server with SSM</a></li>
  <li><a href="#step-11">Step 11: Test the health check</a></li>
  <li><a href="#step-12">Step 12: Test the CPU alarm</a></li>
  <li><a href="#step-13">Step 13: Publish to GitHub</a></li>
  <li><a href="#step-14">Step 14: GitHub Actions pipeline</a></li>
  <li><a href="#step-15">Step 15: Clean up</a></li>
  <li><a href="#troubleshooting">Troubleshooting</a></li>
  <li><a href="#faq">FAQ</a></li>
  <li><a href="#next-ideas">Ideas to extend the project</a></li>
</ol>

<hr>

<h2 id="overview">Overview of the steps</h2>

<table>
  <thead>
    <tr>
      <th>Phase</th>
      <th>Steps</th>
      <th>Time</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Prepare</td><td>1 to 4: get the files, create the state bucket, create settings files</td><td>10 minutes</td></tr>
    <tr><td>Deploy</td><td>5 to 8: init, plan, apply, confirm email</td><td>5 to 10 minutes</td></tr>
    <tr><td>Test</td><td>9 to 12: website, SSM login, health check, CPU alarm</td><td>20 to 30 minutes</td></tr>
    <tr><td>Publish</td><td>13 to 14: GitHub and CI pipeline</td><td>15 minutes</td></tr>
    <tr><td>Clean up</td><td>15: destroy everything</td><td>5 minutes</td></tr>
  </tbody>
</table>

<blockquote>
<b>Reminder:</b> resources created in Step 7 can cost money while they exist. Do Step 15 when you finish testing.
</blockquote>

<h2 id="step-1">Step 1: Get the project and open it in a terminal</h2>

<p>If the project is already on your computer, skip the download. Otherwise, clone it from GitHub (replace the address with your repository):</p>

<pre><code>git clone https://github.com/YOUR_USER/YOUR_REPO.git
cd YOUR_REPO</code></pre>

<p>Check that you are in the right folder. You should see <code>main.tf</code>, <code>variables.tf</code> and <code>user_data.sh</code>:</p>

<pre><code>ls</code></pre>

<p>Every command in this guide is run from this project folder.</p>

<h2 id="step-2">Step 2: Format the code</h2>

<p>Terraform has a built-in formatter. Running it once makes sure the GitHub Actions format check passes later.</p>

<pre><code>terraform fmt -recursive</code></pre>

<p>If it prints file names, it fixed their spacing. If it prints nothing, everything was already formatted. Both are fine.</p>

<h2 id="step-3">Step 3: Create the state bucket</h2>

<p>
Terraform needs a safe place to store its state file. The helper script creates an S3 bucket with versioning (so you can recover old state), encryption, and public access blocked.
</p>

<p>
S3 bucket names must be <b>globally unique</b> across all AWS accounts, use only lowercase letters, numbers and hyphens, and be 3 to 63 characters. A good pattern is <code>yourname-tfstate-12345</code>.
</p>

<pre><code>./bootstrap/create_state_bucket.sh yourname-tfstate-12345 ap-south-1</code></pre>

<p>Expected last lines:</p>

<pre>
State bucket ready: yourname-tfstate-12345 (ap-south-1)
Next: copy backend.hcl.example to backend.hcl and set bucket = "yourname-tfstate-12345"
</pre>

<ul>
  <li>If you see <code>Permission denied</code>, run it as <code>bash bootstrap/create_state_bucket.sh yourname-tfstate-12345 ap-south-1</code>.</li>
  <li>If you see <code>BucketAlreadyExists</code>, the name is taken. Choose another.</li>
  <li>On Windows, run this from Git Bash or WSL, not from PowerShell.</li>
</ul>

<h2 id="step-4">Step 4: Create your settings files</h2>

<p>Two files hold your personal values. Both are ignored by Git, so they are never published.</p>

<h3>4.1 backend.hcl (where the state is stored)</h3>

<pre><code>cp backend.hcl.example backend.hcl</code></pre>

<p>Open <code>backend.hcl</code> in your editor and set your bucket name and region:</p>

<pre><code>bucket       = "yourname-tfstate-12345"
key          = "tf-aws-linux-demo/terraform.tfstate"
region       = "ap-south-1"
encrypt      = true
use_lockfile = true</code></pre>

<h3>4.2 terraform.tfvars (what to build)</h3>

<pre><code>cp terraform.tfvars.example terraform.tfvars</code></pre>

<p>Open <code>terraform.tfvars</code> and set <b>your real email</b>. This is where alarm emails go:</p>

<pre><code>aws_region          = "ap-south-1"
project_name        = "tf-aws-linux-demo"
alert_email         = "you@example.com"
instance_type       = "t3.micro"
cpu_alarm_threshold = 70</code></pre>

<p>The region in <code>backend.hcl</code> must match the bucket's region from Step 3. The region in <code>terraform.tfvars</code> is where the server is built, and it can be the same.</p>

<h2 id="step-5">Step 5: Initialise Terraform</h2>

<pre><code>terraform init -backend-config=backend.hcl</code></pre>

<p>This downloads the AWS provider plugin and connects Terraform to your S3 state bucket. A successful run ends with:</p>

<pre>
Terraform has been successfully initialized!
</pre>

<p>
It also creates a <code>.terraform.lock.hcl</code> file. Keep it and commit it to Git, because it pins the provider version. The <code>.terraform/</code> folder is just a download cache and is ignored by Git.
</p>

<h2 id="step-6">Step 6: Plan</h2>

<pre><code>terraform plan</code></pre>

<p>
A plan is a <b>preview</b>. Nothing is created yet. Terraform compares your code with the real world and lists what it would do. Symbols you will see:
</p>

<table>
  <thead>
    <tr>
      <th>Symbol</th>
      <th>Meaning</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>+</code></td><td>Will be created</td></tr>
    <tr><td><code>~</code></td><td>Will be changed in place</td></tr>
    <tr><td><code>-</code></td><td>Will be destroyed</td></tr>
    <tr><td><code>-/+</code></td><td>Will be destroyed and created again</td></tr>
  </tbody>
</table>

<p>On a first run, the last line should say:</p>

<pre>
Plan: 14 to add, 0 to change, 0 to destroy.
</pre>

<p>The 14 resources are the VPC, internet gateway, subnet, route table, route table association, security group, IAM role, policy attachment, instance profile, EC2 instance, SNS topic, SNS email subscription, and two CloudWatch alarms. Read through the plan once so you recognise each item.</p>

<h2 id="step-7">Step 7: Apply</h2>

<pre><code>terraform apply</code></pre>

<p>Terraform shows the plan again and asks for confirmation. Type <code>yes</code> and press Enter. It takes about 1 to 3 minutes. At the end you will see:</p>

<pre>
Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:

instance_id = "i-0123456789abcdef0"
public_ip = "13.xxx.xxx.xxx"
sns_topic_arn = "arn:aws:sns:ap-south-1:123456789012:tf-aws-linux-demo-alerts"
ssm_session_command = "aws ssm start-session --target i-0123456789abcdef0 --region ap-south-1"
website_url = "http://13.xxx.xxx.xxx"
</pre>

<p>You can print these values again at any time with <code>terraform output</code>.</p>

<p>
<b>Important:</b> Terraform finishes when AWS has created the server, but the server's boot script (<code>user_data.sh</code>) keeps running for 2 to 3 more minutes while it installs Nginx. The website may not answer until then.
</p>

<h2 id="step-8">Step 8: Confirm the email subscription</h2>

<p>
AWS sends an email titled <b>"AWS Notification - Subscription Confirmation"</b> to the address you set in <code>terraform.tfvars</code>. Open it and click <b>Confirm subscription</b>. Without this, alarm emails will never arrive. Check your spam folder if you cannot find it.
</p>

<h2 id="step-9">Step 9: Open the website</h2>

<p>Wait about 3 minutes after the apply finishes, then print the address:</p>

<pre><code>terraform output website_url</code></pre>

<p>
Open it in a browser. Use <code>http://</code>, not <code>https://</code>, because this project does not set up HTTPS. You should see a page titled <b>"Provisioned with Terraform"</b> showing the host name, instance ID and availability zone. That page was written by the boot script, so seeing it proves the whole chain works: network, firewall, server and Nginx.
</p>

<p>You can also test from the terminal:</p>

<pre><code>curl $(terraform output -raw website_url)</code></pre>

<h2 id="step-10">Step 10: Log in to the server with SSM</h2>

<p>
There is no SSH key and no open SSH port. You connect through AWS Systems Manager Session Manager instead. Use whichever way is easier for you.
</p>

<p><b>Option A: from your terminal</b> (needs the Session Manager plugin)</p>

<pre><code>aws ssm start-session --target $(terraform output -raw instance_id) --region ap-south-1</code></pre>

<p><b>Option B: from the browser</b></p>

<ol>
  <li>Open the AWS console and go to <b>EC2</b>, then <b>Instances</b>.</li>
  <li>Select the instance named <code>tf-aws-linux-demo-web</code>.</li>
  <li>Click <b>Connect</b>, open the <b>Session Manager</b> tab, and click <b>Connect</b>.</li>
</ol>

<p>If the connect button is greyed out or says the target is not connected, wait 2 to 5 minutes after the apply. The SSM agent needs a little time to register.</p>

<p>Once you have a shell, look around:</p>

<pre><code>sudo su - ec2-user                          # optional, switch to the normal user
systemctl status nginx                      # should say active (running)
curl -s localhost | head                    # the page, served locally
cat /etc/cron.d/healthcheck                 # the 5-minute schedule
cat /usr/local/bin/healthcheck.sh           # the health check script
sudo tail -n 40 /var/log/cloud-init-output.log   # output of user_data.sh from first boot</code></pre>

<p>Type <code>exit</code> to leave the session.</p>

<h2 id="step-11">Step 11: Test the health check</h2>

<p>The cron job runs every 5 minutes. If Nginx is not answering, it restarts it and writes a line to a log file. Let's break Nginx on purpose and watch it heal.</p>

<p>Inside the SSM session:</p>

<pre><code>sudo systemctl stop nginx
systemctl is-active nginx                   # prints: inactive</code></pre>

<p>The website is now down. Wait up to 5 minutes, then check:</p>

<pre><code>sudo tail /var/log/healthcheck.log          # a line saying nginx unhealthy, restarting
systemctl is-active nginx                   # prints: active</code></pre>

<p>Refresh the website in your browser. It should be back without you touching anything. That is a simple self-healing mechanism.</p>

<h2 id="step-12">Step 12: Test the CPU alarm</h2>

<p>The alarm fires when average CPU stays above 70 percent for two consecutive 5-minute periods. We will create artificial load.</p>

<p>Inside the SSM session:</p>

<pre><code>sudo dnf install -y stress-ng
stress-ng --cpu 2 --timeout 900             # 15 minutes of full CPU load</code></pre>

<p>Now watch:</p>

<ol>
  <li>Open the AWS console, go to <b>CloudWatch</b>, then <b>Alarms</b>.</li>
  <li>Click <code>tf-aws-linux-demo-cpu-high</code>. It starts as <b>OK</b> or <b>Insufficient data</b>.</li>
  <li>After about 10 to 15 minutes it changes to <b>In alarm</b>, and an email arrives from AWS Notifications.</li>
  <li>When the stress test ends, the alarm returns to <b>OK</b> and you get a second email, because the alarm is also set to notify on recovery.</li>
</ol>

<blockquote>
<b>Cost note:</b> t3 instances can burst above their baseline CPU, and AWS may charge a few cents for the extra CPU credits if you stress for a long time. A 15-minute test is cheap. Do not leave the stress test running.
</blockquote>

<h2 id="step-13">Step 13: Publish to GitHub</h2>

<h3>13.1 Create an empty repository</h3>

<ol>
  <li>On GitHub, click <b>New repository</b>.</li>
  <li>Name it, for example <code>terraform-aws-linux-monitoring</code>.</li>
  <li>Do <b>not</b> add a README, .gitignore or licence. The project already has them.</li>
</ol>

<h3>13.2 Check what will be uploaded</h3>

<pre><code>git init
git add .
git status</code></pre>

<p>Read the list carefully. You should see the <code>.tf</code> files, <code>user_data.sh</code>, <code>.terraform.lock.hcl</code>, <code>README.md</code>, <code>docs/</code>, <code>bootstrap/</code>, <code>.github/</code> and <code>.gitignore</code>. You must <b>not</b> see any of these:</p>

<ul>
  <li><code>terraform.tfvars</code></li>
  <li><code>backend.hcl</code></li>
  <li>anything ending in <code>.tfstate</code></li>
  <li>the <code>.terraform/</code> folder</li>
  <li>any file containing an AWS access key</li>
</ul>

<p>If any of them appear, stop and fix <code>.gitignore</code> before continuing.</p>

<h3>13.3 Commit and push</h3>

<pre><code>git commit -m "Add Terraform AWS Linux server with monitoring"
git branch -M main
git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
git push -u origin main</code></pre>

<p>Open the repository page in your browser. The README should render with tables and headings. If it looks wrong, tell me what you see.</p>

<h2 id="step-14">Step 14: GitHub Actions pipeline</h2>

<p>The file <code>.github/workflows/terraform.yml</code> defines the pipeline. It has two jobs.</p>

<table>
  <thead>
    <tr>
      <th>Job</th>
      <th>When it runs</th>
      <th>What it does</th>
      <th>Needs AWS access?</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>validate</code></td><td>On every pull request and push to main</td><td>Checks formatting (<code>terraform fmt -check</code>), initialises without a backend, and runs <code>terraform validate</code></td><td>No</td></tr>
    <tr><td><code>plan</code></td><td>On pull requests, only if the repository variable <code>AWS_ROLE_ARN</code> is set</td><td>Logs in to AWS with a temporary role and runs <code>terraform plan</code></td><td>Yes</td></tr>
  </tbody>
</table>

<h3>14.1 See the validate job work (no AWS setup needed)</h3>

<pre><code>git checkout -b test-ci
# make a small change, for example add a comment to variables.tf
git add .
git commit -m "Test CI pipeline"
git push -u origin test-ci</code></pre>

<p>On GitHub, open a <b>pull request</b> from <code>test-ci</code> to <code>main</code>. Scroll to the checks section, or open the <b>Actions</b> tab. The <code>fmt and validate</code> job should turn green. If it fails on formatting, run <code>terraform fmt -recursive</code> locally, commit, and push again.</p>

<h3>14.2 Optional: turn on the plan job</h3>

<p>
The plan job needs permission to read your AWS account. Instead of storing AWS keys in GitHub (unsafe), it uses <b>OIDC</b>: GitHub proves its identity to AWS and receives short-lived credentials. This is the modern, recommended method.
</p>

<p><b>1. Create the identity provider in AWS</b> (once per account)</p>

<ol>
  <li>Open <b>IAM</b>, then <b>Identity providers</b>, then <b>Add provider</b>.</li>
  <li>Choose <b>OpenID Connect</b>.</li>
  <li>Provider URL: <code>https://token.actions.githubusercontent.com</code></li>
  <li>Audience: <code>sts.amazonaws.com</code></li>
  <li>Click <b>Add provider</b>.</li>
</ol>

<p><b>2. Create the role</b></p>

<ol>
  <li>Open <b>IAM</b>, then <b>Roles</b>, then <b>Create role</b>.</li>
  <li>Choose <b>Custom trust policy</b> and paste the policy below. Replace <code>ACCOUNT_ID</code>, <code>YOUR_GITHUB_USER</code> and <code>YOUR_REPO</code>.</li>
  <li>Name the role <code>github-terraform-plan</code>.</li>
</ol>

<pre><code>{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USER/YOUR_REPO:pull_request"
        }
      }
    }
  ]
}</code></pre>

<p>The <code>sub</code> condition is the safety lock: only pull requests from <b>your</b> repository can use this role.</p>

<p><b>3. Give the role permissions</b></p>

<p>A plan only needs to read your account and read and lock the state file. Attach the AWS managed policy <b>ReadOnlyAccess</b>, and add this inline policy for the state bucket (replace the bucket name):</p>

<pre><code>{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::yourname-tfstate-12345"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::yourname-tfstate-12345/*"
    }
  ]
}</code></pre>

<p><b>4. Set the repository variables</b></p>

<p>On GitHub, go to <b>Settings</b>, then <b>Secrets and variables</b>, then <b>Actions</b>, then the <b>Variables</b> tab, and add:</p>

<table>
  <thead>
    <tr>
      <th>Variable</th>
      <th>Value</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>AWS_ROLE_ARN</code></td><td>The ARN of the role you just created, for example <code>arn:aws:iam::123456789012:role/github-terraform-plan</code></td></tr>
    <tr><td><code>AWS_REGION</code></td><td><code>ap-south-1</code></td></tr>
    <tr><td><code>TF_STATE_BUCKET</code></td><td>Your state bucket name</td></tr>
    <tr><td><code>ALERT_EMAIL</code></td><td>Your email address</td></tr>
  </tbody>
</table>

<p>Open a new pull request. The <code>plan</code> job now appears. If you ran Step 7 already and nothing has changed, it should report <b>No changes</b>.</p>

<p>This pipeline deliberately does <b>not</b> run <code>apply</code>. Letting CI create or destroy infrastructure needs extra safeguards such as manual approvals, so it is listed under ideas at the end of this guide.</p>

<h2 id="step-15">Step 15: Clean up</h2>

<p>When you finish, remove everything so you stop paying for it.</p>

<h3>15.1 Destroy the infrastructure</h3>

<pre><code>terraform destroy</code></pre>

<p>Type <code>yes</code> when asked. It should end with:</p>

<pre>
Destroy complete! Resources: 14 destroyed.
</pre>

<h3>15.2 Check nothing is left running</h3>

<pre><code>aws ec2 describe-instances --region ap-south-1 \
  --filters "Name=tag:Project,Values=tf-aws-linux-demo" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query "Reservations[].Instances[].InstanceId"</code></pre>

<p>An empty list <code>[]</code> means the server is gone.</p>

<h3>15.3 Delete the state bucket (optional)</h3>

<p>
The state bucket has versioning on, so the simple <code>aws s3 rb --force</code> command will <b>not</b> work: old versions are kept. Use the console:
</p>

<ol>
  <li>Open <b>S3</b> and select your state bucket.</li>
  <li>Click <b>Empty</b>, type the confirmation text, and confirm. This removes all versions.</li>
  <li>Go back, select the bucket again, click <b>Delete</b>, and confirm.</li>
</ol>

<p>The state bucket costs almost nothing, so you may also keep it for your next Terraform project.</p>

<h3>15.4 Other tidying</h3>

<ul>
  <li>If you created the GitHub OIDC role and no longer need it, delete the role and the identity provider in IAM.</li>
  <li>If you created an access key just for this project, delete it in IAM, then Users, then Security credentials.</li>
  <li>Check <b>Billing and Cost Management</b> the next day to confirm charges are zero or tiny.</li>
</ul>

<h2 id="troubleshooting">Troubleshooting</h2>

<table>
  <thead>
    <tr>
      <th>Problem or message</th>
      <th>Likely cause</th>
      <th>Fix</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>No valid credential sources found</code> or <code>InvalidClientTokenId</code></td>
      <td>AWS CLI is not configured, or the keys are wrong</td>
      <td>Run <code>aws configure</code>, then <code>aws sts get-caller-identity</code> until it shows your account</td>
    </tr>
    <tr>
      <td><code>Unsupported Terraform Core version</code> or <code>Unsupported argument "use_lockfile"</code></td>
      <td>Terraform is older than 1.10</td>
      <td>Upgrade Terraform and check with <code>terraform version</code></td>
    </tr>
    <tr>
      <td><code>BucketAlreadyExists</code></td>
      <td>Someone else already uses that bucket name</td>
      <td>Pick a more unique name and rerun the script</td>
    </tr>
    <tr>
      <td><code>Backend initialization required</code></td>
      <td>You skipped init or changed backend settings</td>
      <td>Run <code>terraform init -backend-config=backend.hcl</code></td>
    </tr>
    <tr>
      <td><code>No value for required variable</code> (alert_email)</td>
      <td><code>terraform.tfvars</code> is missing or in the wrong folder</td>
      <td>Create it from the example, in the project folder</td>
    </tr>
    <tr>
      <td><code>AccessDenied</code> or <code>UnauthorizedOperation</code></td>
      <td>Your IAM user lacks a permission</td>
      <td>Check the user's policies. For learning, use AdministratorAccess in a personal account</td>
    </tr>
    <tr>
      <td>Instance type not supported or not eligible for free tier</td>
      <td>That size is unavailable in your region or zone, or your account's free-tier rules differ</td>
      <td>Set <code>instance_type</code> to another small type such as <code>t2.micro</code>, or change region</td>
    </tr>
    <tr>
      <td><code>Error acquiring the state lock</code></td>
      <td>A previous Terraform run was interrupted, or another run is active</td>
      <td>Wait a few minutes and retry. Only if you are sure no other run is active, use <code>terraform force-unlock LOCK_ID</code> with the ID from the message</td>
    </tr>
    <tr>
      <td>Website does not load</td>
      <td>Boot script still running, or you used https</td>
      <td>Wait 3 to 5 minutes and use <code>http://</code>. If it still fails, connect with SSM and run <code>sudo tail -n 60 /var/log/cloud-init-output.log</code></td>
    </tr>
    <tr>
      <td>SSM: <code>TargetNotConnected</code> or the Connect button is disabled</td>
      <td>The SSM agent has not registered yet, or the plugin is missing</td>
      <td>Wait a few minutes. Install the Session Manager plugin, and include <code>--region</code> in the command</td>
    </tr>
    <tr>
      <td>No alarm email</td>
      <td>Subscription was never confirmed, or the email went to spam</td>
      <td>Check spam, or in the SNS console confirm the subscription status is Confirmed</td>
    </tr>
    <tr>
      <td>CI fails at <code>terraform fmt -check</code></td>
      <td>Files are not formatted</td>
      <td>Run <code>terraform fmt -recursive</code>, commit, push</td>
    </tr>
    <tr>
      <td><code>$'\r': command not found</code> when running a script</td>
      <td>Windows line endings in the script</td>
      <td>Run the scripts from WSL, or run <code>git config core.autocrlf input</code> and clone again</td>
    </tr>
    <tr>
      <td><code>Permission denied</code> running a script</td>
      <td>The file is not marked executable</td>
      <td>Run it with <code>bash bootstrap/create_state_bucket.sh ...</code> or <code>chmod +x bootstrap/create_state_bucket.sh</code></td>
    </tr>
  </tbody>
</table>

<h2 id="faq">FAQ</h2>

<p><b>Why not just click in the AWS console?</b><br>
Code can be reviewed, versioned, repeated and deleted in one command. A console setup lives only in someone's memory.</p>

<p><b>What does <code>terraform plan</code> actually compare?</b><br>
Your code, the state file, and the real resources in AWS. Anything that differs becomes a proposed change.</p>

<p><b>Why do we need a state file at all?</b><br>
It records which real resource belongs to which block of code. Without it, Terraform could not update or delete anything safely.</p>

<p><b>Why S3 for the state instead of my laptop?</b><br>
It is backed up (versioning), shared with teammates and CI, and protected against two people changing things at once (locking).</p>

<p><b>Can I use another region?</b><br>
Yes. Change <code>aws_region</code> in <code>terraform.tfvars</code>, and create the state bucket in a region you like. Some instance types are not available in every region or zone.</p>

<p><b>Can I use SSH instead of SSM?</b><br>
It is deliberately left out. SSH needs an open port and key management. SSM needs neither, and every session is controlled by IAM and can be logged.</p>

<p><b>How do I change the server size?</b><br>
Edit <code>instance_type</code> in <code>terraform.tfvars</code>, run <code>terraform plan</code> to preview, then <code>terraform apply</code>.</p>

<p><b>What happens if I change <code>user_data.sh</code>?</b><br>
The project sets <code>user_data_replace_on_change</code>, so Terraform replaces the server with a fresh one that runs the new script. The old server is destroyed and the public IP changes.</p>

<p><b>Where does the 70 percent in the alarm come from?</b><br>
The variable <code>cpu_alarm_threshold</code>. Change it in <code>terraform.tfvars</code> and apply.</p>

<p><b>Is it safe to leave port 80 open to everyone?</b><br>
For a public demo page, yes. For a real application, put a load balancer or CDN in front, use HTTPS, and restrict access where possible.</p>

<h2 id="next-ideas">Ideas to extend the project</h2>

<p>Once the basics work, these make good next steps and strong talking points:</p>

<ul>
  <li><b>Application Load Balancer and Auto Scaling group</b> instead of a single server, so the site survives a server failure.</li>
  <li><b>HTTPS</b> with an AWS Certificate Manager certificate and a custom domain in Route 53.</li>
  <li><b>CloudWatch agent</b> to collect memory and disk metrics, which EC2 does not report by default, and a dashboard.</li>
  <li><b>Terraform modules</b> to split the network and the server into reusable pieces.</li>
  <li><b>Security scanning</b> in CI with tools such as tfsec or Checkov.</li>
  <li><b>Cost estimates</b> in pull requests with Infracost.</li>
  <li><b>Apply pipeline</b> with a manual approval step and separate environments (dev and prod).</li>
  <li><b>Configuration management</b> with Ansible instead of a boot script.</li>
  <li><b>Docker</b>: run the app as a container and push images to Amazon ECR.</li>
</ul>

<hr>
