# shell-blesh-mistral-LLMs

Blesh, Bash Line Editor, linked to AI Mistral LLMs to enpowers shell command generation tasks, including fill-in-the-middle and command autocompletion.

## Installation

### Dependencies

Install blesh first (refer to §Quick-Instructions https://github.com/K-PANIK/ble.sh?tab=readme-ov-file#quick-instructions)

```sh
# Example : Quick INSTALL to BASHRC
git clone --recursive --depth 1 --shallow-submodules https://github.com/K-PANIK/ble.sh
make -C ble.sh install PREFIX=~/.local
echo 'source ~/.local/share/blesh/ble.sh' >> ~/.bashrc
```

### Configuration

You need to have a model api private key with access to `MISTRAL LLMs` to use it (https://console.mistral.ai/build/agents).

1. Expose your key via the `MISTRAL_API_KEY` environment variable:

    ```sh
    echo "export MISTRAL_API_KEY=<your-api-key>" >> ~/.bashrc
    ```
2. Clone repository 
    ```sh
    git clone  https://github.com/K-PANIK/shell-blesh-mistral-LLMs.git --branch=main
    cd shell-blesh-mistral-LLMs/
    ```
3. Configure shell-blesh-mistral-LLMs script at bash startup:
    ```sh
    echo "source $(pwd)/blesh-mistral.sh" >> ~/.bashrc
    ```

### How to use

Just press `CTRL + t` and get your suggestion. Suggestion can be autocompletion or new command.
Talk to Mistal directly by starting your command with hashtag #

### Here are some examples
  * User input: 'list files in current directory'; Your response: '=ls # ls is the builtin command for listing files'
  * User input: 'cd /tm'; Your response: '+p # /tmp is the standard temp folder on linux and mac'.
  * User input: 'curl -O http'; Your response: '+s://www.example.com'.
  * User input: '# Who are you?'; Your response: 'I am $AI_MODEL. What can I do for you?'.
