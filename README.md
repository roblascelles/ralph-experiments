
# Ralph Experiments

## Using https://github.com/soderlind/ralph?tab=readme-ov-file from a container

Install GH CLI locally : https://cli.github.com/
```
brew install gh
```

Build container for agent:
```
docker build -t copilot-ralph-sandbox .
```

clone cli runner
```
git clone https://github.com/soderlind/ralph
```

authenticate with GH
```
gh auth login
export GH_TOKEN=$(gh auth token)
```

start agent:
```
docker compose up -d
```

connect to agent:
```
docker exec -it ralph_sandbox tmux attach -t ralph_loop
```

install copilot extension in agent:
```
gh extension install github/gh-copilot
```

run ralph
```
cd ralph
MODEL=claude-sonnet-4.5 ./ralph-once.sh --prompt prompts/default.txt --prd plans/prd.json --allow-profile safe
```


--- 

install copilot cli (optional)
```
# Check version
copilot --version

# Homebrew
brew update && brew install copilot

# npm
npm i -g @github/copilot

# Windows
winget upgrade GitHub.Copilot
```