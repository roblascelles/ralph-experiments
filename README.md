
# Ralph Experiments

Attempting to build a simple application via the [Ralph Wiggum](https://ghuntley.com/ralph/) flow.

## Using copilot cli from container

Install GH CLI locally : https://cli.github.com/
```
brew install gh
```

authenticate with GH
```
gh auth login
export GH_TOKEN=$(gh auth token)
```

start agent:
```
docker compose up -d --build 
```

connect to agent (-CC for tmux integration with iTerm2)
```
docker exec -it ralph_sandbox tmux -CC attach -t ralph_loop
```

