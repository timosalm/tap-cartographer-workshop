**Persona: Developers**

The inital version of our project is now ready to be pushed to a repository of a version control system like Git to make it available to other team members.

```terminal:execute
command: |
  git init
  git add .
  git commit -m "Initial commit"
  git branch -M $GIT_BRANCH
  git remote add origin {{ ENV_APP_GIT_REPO_SSH_URL }}
  git push -u origin $GIT_BRANCH
clear: true
```