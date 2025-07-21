import jenkins
import getpass
import argparse
import os

# Argument parsing
parser = argparse.ArgumentParser(description='Create Jenkins pipeline jobs for AMI builders.')
parser.add_argument('--jenkins-url', help='Jenkins URL (e.g., http://localhost:8080)')
parser.add_argument('--username', help='Jenkins username')
parser.add_argument('--api-token', help='Jenkins API token')
parser.add_argument('--repo-url', help='Git repository URL', default=None)
args = parser.parse_args()

# Environment variable fallback
JENKINS_URL = args.jenkins_url or os.environ.get('JENKINS_URL')
USERNAME = args.username or os.environ.get('JENKINS_USER')
API_TOKEN = args.api_token or os.environ.get('JENKINS_TOKEN')
REPO_URL = args.repo_url or os.environ.get('REPO_URL') or 'https://github.com/ctrlalttaco/vibe-coding-packer.git'

# Prompt if still missing
if not JENKINS_URL:
    JENKINS_URL = input('Jenkins URL (e.g., http://localhost:8080): ').strip()
if not USERNAME:
    USERNAME = input('Jenkins username: ').strip()
if not API_TOKEN:
    API_TOKEN = getpass.getpass('Jenkins API token: ')

PIPELINES = [
    {
        'name': 'ami-builder-main',
        'jenkinsfile': 'Jenkinsfile',
        'description': 'Multi-distro Linux AMI builds'
    }
]

# Jenkins pipeline job XML template
PIPELINE_JOB_XML = '''
<flow-definition plugin="workflow-job">
  <description>{description}</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>{repo_url}</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>{jenkinsfile}</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
'''

def main():
    try:
        server = jenkins.Jenkins(JENKINS_URL, username=USERNAME, password=API_TOKEN)
        user = server.get_whoami()
        print(f'Connected to Jenkins as {user["fullName"]}')
    except Exception as e:
        print(f'Error connecting to Jenkins: {e}')
        return

    for pipeline in PIPELINES:
        job_name = pipeline['name']
        job_xml = PIPELINE_JOB_XML.format(
            description=pipeline['description'],
            repo_url=REPO_URL,
            jenkinsfile=pipeline['jenkinsfile']
        )
        try:
            if server.job_exists(job_name):
                print(f'Job {job_name} already exists. Updating...')
                server.reconfig_job(job_name, job_xml)
            else:
                print(f'Creating job {job_name}...')
                server.create_job(job_name, job_xml)
            print(f'Job {job_name} configured successfully.')
        except Exception as e:
            print(f'Error configuring job {job_name}: {e}')

if __name__ == '__main__':
    main() 