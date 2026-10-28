#!/usr/bin/env nu
# Ask the configured endpoint one question with tools, and print what came back.
#
# A probe, not a client. A turn goes prism -> gravity -> provider, and when a turn ends
# with no reply and no tool effect the first thing to separate is "the model never
# asked" from "the ask was lost on the way". This answers the first half: it bypasses
# the stack entirely and talks to the endpoint in the shape gravity uses.
#
# The key comes from the secrets file through the environment, never from argv.
use lib.nu *

def main [
    --question: string = "Open a task named verify-the-stack."  # what to ask
] {
    let key_name = "OPENAI_API_KEY"
    let key = ((stack-env) | get $key_name)
    let url = $"((endpoint) | str trim --right --char /)/chat/completions"

    let body = {
        model: (model)
        messages: [
            { role: "system", content: "You are a test harness. Call the tool that is asked for." }
            { role: "user", content: $question }
        ]
        tools: [{
            type: "function"
            function: {
                name: "open_task"
                description: "Open a task."
                parameters: {
                    type: "object"
                    properties: { name: { type: "string" } }
                    required: ["name"]
                }
            }
        }]
        stream: false
    }

    let answer = (http post --content-type application/json
        --headers { Authorization: $"Bearer ($key)" }
        $url $body)

    let choice = ($answer.choices | get 0)
    print (ansi green)"finish_reason"(ansi reset)
    print $"  ($choice.finish_reason)"
    print (ansi green)"content"(ansi reset)
    print $"  ($choice.message.content? | default '' | describe)"
    print (ansi green)"tool_calls"(ansi reset)
    let calls = ($choice.message.tool_calls? | default [])
    if ($calls | is-empty) {
        print "  (none — the model did not ask for a tool)"
    } else {
        for call in $calls {
            print $"  ($call.function.name)  ($call.function.arguments)"
        }
    }
}