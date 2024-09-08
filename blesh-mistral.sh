#!/bin/bash
CUR_DATE=`date`
AI_MODEL="mistral-large-latest"
echo "BLESH MISTRAL AI (model=$AI_MODEL) is loaded at $CUR_DATE"

[ ! ${ASSIST_KEY} ] && typeset -g ASSIST_KEY='C-t'
[ ! ${SEND_CONTEXT} ] && typeset -g SEND_CONTEXT=true
[ ! ${ASSIST_DEBUG} ] && typeset -g ASSIST_DEBUG=false

#SYSTEM INSTRUCTION
SYSTEM_PROMPT=""
read -r -d '' SYSTEM_PROMPT <<- EOM
You will be given the raw input of a shell command. 
Your task is to either complete the command or provide a new command that you think the user is trying to type. 
If you return a completely new command for the user, prefix it ONLY with the equal sign (=). 
Else if you return a completion for the user's command, prefix it ONLY with the plus sign (+). 
Only respond with either a completion or a new command, not both. 
Your response SHALL NOT start with the two consecutive signs! This means that IT IS FORBIDEN your response starts with '+=' or '=+'. 
In case of completion reponse, always MAKE SURE TO ONLY INCLUDE THE REST OF THE COMPLETION. NEVER repeat user command in your response for a completion. 
Do not write any leading or trailing characters except if required for the completion to work. 
Your response may only start with either a plus sign or an equal sign because user program goes to chech your response first character (check sign). 
You MAY explain the command by writing a short line after the comment symbol (#). 
Do not ask for more information, you won't receive it. 
Your response will be run in the user's shell. 
Make sure input is escaped correctly if needed so. 
Your input should be able to run without any modifications to it. 
Don't you dare to return anything else other than shell command !!!
All shell command shall be split with a comma (;). And after the first command, check sign of other commands are not necessary. 
DO NOT INTERACT WITH THE USER IN NATURAL LANGUAGE! If you think you need to do because user need a complet assistance, so give all you responses by comments (beginning with a hashtag #). 
Note that the double quote sign is escaped. Keep this in mind when you create quotes. 
Exception case, if user command starts with a hashtag (#), it means it is not a user shell command and user wants to talk with you, SO you have to answer INLINE by using natural language in COMMENT (without sign check but beginning with hashtag).
In that exceptional case, in only one LINE you are allowed to give lot of details about you and you always have to finish your answer with mannerliness, completed by your model name and your model version.
Here are some examples: 
  * User input: 'list files in current directory'; Your response: '=ls # ls is the builtin command for listing files' 
  * User input: 'cd /tm'; Your response: '+p # /tmp is the standard temp folder on linux and mac'.
  * User input: 'curl -O http'; Your response: '+s://www.example.com'.
  * User input: '# Who are you?'; Your response: 'I am $AI_MODEL. What can I do for you?'.
EOM

if [[ "$OSTYPE" == "darwin"* ]]; then
    SYSTEM="Your system is ${$(sw_vers | xargs | sed 's/ /./g')}."
else 
    SYSTEM="Your system is "`cat /etc/*-release | xargs | sed 's/ /,/g'`
fi

function ia_shell_assistance() {

	if [[ "$SEND_CONTEXT" == 'true' ]]; then
        local PROMPT="$SYSTEM_PROMPT 
            Context: You are user $(whoami) with id $(id) in directory $(pwd). 
            Your shell is $(echo $SHELL) and your terminal is $(echo $TERM) running on $(uname -a).
            $SYSTEM"
    fi
    
    # Get input
    user_input=${_ble_edit_str}    
    input=$(echo "${user_input}" | tr '\n' ';')
    input=$(echo "$input" | sed 's/"/\\"/g')

    if [[ "$input" == "" ]] || [[ "$input" == ";" ]];
	then
		echo "Failed : current edit command line is empty."
		return 0
    fi

	PROMPT=$(echo "$PROMPT" | tr -d '\n')
			
	data="{
				\"model\": \"${AI_MODEL}\",
				\"messages\": [
					{
						\"role\": \"system\",
						\"content\": \"$PROMPT\"
					},
					{
						\"role\": \"user\",
						\"content\": \"$input\"
					}
				]
			}"
			
	IA_KEY="${MISTRAL_API_KEY}"
	
	response=`curl --location "https://api.mistral.ai/v1/chat/completions" \
				   --header 'Content-Type: application/json' \
				   --header 'Accept: application/json' \
				   --header "Authorization: Bearer $MISTRAL_API_KEY" \
				   --data "$data" 2>/dev/null`
	message=$(echo "$response" | jq -r .choices[0].message.content)

	char_key=${message:0:1}
	suggestion=${message:1:${#message}}

	if [[ "$ASSIST_DEBUG" == 'true' ]]; then
		LOG_FILE='/tmp/shell_assistant.log'
		touch $LOG_FILE
		echo $CUR_DATE > $LOG_FILE
		echo -e "$(date);\nINPUT:[$input];\nRESPONSE:$response;\nFIRST_CHAR:$char_key;\nSUGGESTION:$suggestion;\nDATA:$data" >> $LOG_FILE
	fi

	if [[ "$char_key" == '=' ]]; 
	then
        # output model failure check
        if [ ${suggestion:0:1} == '+' ];
        then
            suggestion=${suggestion:1:${#suggestion}}
            if [ $ASSIST_DEBUG == "true" ];
            then
                suggestion=${suggestion}" # (ai debug corrected)"
            fi
        fi
		# Reset edit prompt input
		ble/widget/.newline/clear-content
    	ble/widget/insert-string ${suggestion}
    	ble/widget/end-of-logical-line
    	
	elif [[ "$char_key" == '+' ]]; 
	then
        # output model failure check
        if [ ${suggestion:0:1} == '=' ];
        then
            suggestion=${suggestion:1:${#suggestion}}
            if [ $ASSIST_DEBUG == "true" ];
            then
                suggestion=${suggestion}" # (ai debug corrected)"
            fi
        fi	
    	ble/widget/insert-string "${suggestion}"

	elif [[ "$char_key" == '#' ]]; 
	then
	    ble/widget/.newline/clear-content
		ble/widget/insert-string "#${suggestion}"
    	ble/widget/end-of-logical-line

	fi
	
}

# online help
function shell-blesh-mistral-LLMs() {
    echo "blesh-mistral is running. Press $ASSIST_KEY to get suggestions."
    echo ""
    echo "Configurations:"
    echo "    - ASSIST_KEY: Key to press to get suggestions (default: crtl+t, value: $ASSIST_KEY)."
    echo "    - SEND_CONTEXT: If \`true\`, system model configuration will send context information (whoami, shell, pwd, etc.) to the AI model (default: true, value: $SEND_CONTEXT)."
	echo "    - ASSIST_DEBUG: If \`true\`, debug mode is enable to generate model input/output into file /tmp/shell_assistant.log."
}

ble-bind -c ${ASSIST_KEY} ia_shell_assistance

#EOF