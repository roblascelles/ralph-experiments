# Use Python 3.11 as the base image
FROM python:3.11-bookworm

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    tmux \
    sudo \
    gpg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Node.js 22 (Required for GitHub Copilot CLI)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# 3. Install GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh

# 4. Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bookworm stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-compose-plugin

# 5. Install GitHub Copilot CLI globally
RUN npm i -g @github/copilot

# 6. Set up a non-root user 'ralph' for security
RUN groupadd -g 999 docker || true \
    && useradd -m -s /bin/bash ralph \
    && echo "ralph ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && usermod -aG docker ralph
USER ralph
WORKDIR /home/ralph/workspace

# (Optional) Pre-install Python dependencies if the loop script has a requirements.txt
# RUN pip install requests ...

CMD ["/bin/bash"]