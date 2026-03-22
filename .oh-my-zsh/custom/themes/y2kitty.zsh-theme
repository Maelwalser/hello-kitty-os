# y2kitty.zsh-theme
# A structural application of Y2K Sanrio aesthetics to the Zsh prompt.

# Establish True Color Hex Variables for high-fidelity rendering
HK_PASTEL="%F{#ffb6c1}"
HK_HOTPINK="%F{#ff1493}"
HK_WHITE="%F{#ffffff}"
HK_BLUE="%F{#87cefa}"
RESET="%f"

# Git Status Integration
# We define specific visual indicators for repository states.
ZSH_THEME_GIT_PROMPT_PREFIX="${HK_HOTPINK}💕 git:(${RESET}${HK_PASTEL}"
ZSH_THEME_GIT_PROMPT_SUFFIX="${HK_HOTPINK})${RESET}"
ZSH_THEME_GIT_PROMPT_DIRTY=" ${HK_HOTPINK}✗${RESET}"
ZSH_THEME_GIT_PROMPT_CLEAN=" ${HK_BLUE}✨${RESET}"

# Core Prompt Logic (Left Side)
# Format: 
# ╭─🎀 user@machine in directory
# ╰─✨ ❯
PROMPT='
${HK_HOTPINK}╭─${RESET}${HK_PASTEL}🎀 %n${RESET}${HK_HOTPINK}@${RESET}${HK_WHITE}%m${RESET} ${HK_HOTPINK}in${RESET} ${HK_BLUE}%~${RESET}
${HK_HOTPINK}╰─${RESET}${HK_PASTEL}✨ ❯${RESET} '

# Right Prompt Logic (Git Status)
# Isolating Git data to the right side improves terminal legibility.
RPROMPT='$(git_prompt_info)'
