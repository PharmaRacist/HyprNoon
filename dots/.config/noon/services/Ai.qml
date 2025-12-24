pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common.functions as CF
import qs.modules.common
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.services.ai

/**
 * Basic service to handle LLM chats. Supports Google's and OpenAI's API formats.
 * Supports Gemini and OpenAI models.
 * Limitations:
 * - For now functions only work with Gemini API format
 */
Singleton {
    id: root

    property Component aiMessageComponent: AiMessageData {}
    property Component aiModelComponent: AiModel {}
    property Component geminiApiStrategy: GeminiApiStrategy {}
    property Component openaiApiStrategy: OpenAiApiStrategy {}
    property Component mistralApiStrategy: MistralApiStrategy {}
    readonly property string interfaceRole: "interface"
    readonly property string apiKeyEnvVarName: "API_KEY"

    signal responseFinished

    property string systemPrompt: {
        let prompt = Mem.options.ai?.systemPrompt ?? "";
        for (let key in root.promptSubstitutions) {
            // prompt = prompt.replaceAll(key, root.promptSubstitutions[key]);
            // QML/JS doesn't support replaceAll, so use split/join
            prompt = prompt.split(key).join(root.promptSubstitutions[key]);
        }
        return prompt;
    }
    // property var messages: []
    property var messageIDs: []
    property var messageByID: ({})
    readonly property var apiKeys: KeyringStorage.keyringData?.apiKeys ?? {}
    readonly property var apiKeysLoaded: KeyringStorage.loaded
    readonly property bool currentModelHasApiKey: {
        const model = models[currentModelId];
        if (!model || !model.requires_key)
            return true;
        if (!apiKeysLoaded)
            return false;
        const key = apiKeys[model.key_id];
        return (key?.length > 0);
    }
    property var postResponseHook
    property real temperature: Mem.options.ai?.temperature ?? 0.5
    property QtObject tokenCount: QtObject {
        property int input: -1
        property int output: -1
        property int total: -1
    }

    function idForMessage(message) {
        // Generate a unique ID using timestamp and random value
        return Date.now().toString(36) + Math.random().toString(36).substr(2, 8);
    }

    function safeModelName(modelName) {
        return modelName.replace(/:/g, "_").replace(/ /g, "-").replace(/\//g, "-");
    }

    property list<var> defaultPrompts: []
    property list<var> userPrompts: []
    property list<var> promptFiles: [...defaultPrompts, ...userPrompts]
    property list<var> savedChats: []

    property var promptSubstitutions: {
        "{DISTRO}": SystemInfo.distroName,
        "{DATETIME}": `${DateTimeService.time}, ${DateTimeService.collapsedCalendarFormat}`,
        "{WINDOWCLASS}": `${ToplevelManager.activeToplevel?.appId} ${ToplevelManager.activeToplevel?.title}` ?? "Unknown",
        "{DE}": `${SystemInfo.desktopEnvironment} (${SystemInfo.windowingSystem})`,
        "{TASKS}": formatTasks(),
        "{TIMERS}": formatTimers(),
        "{USER}": SystemInfo.username,
        "{LOCATION}": Mem.options.services.location,
        "{NOTES}": NotesService.content,
        "{PLAYING}": `title:${BeatsService.cleanedTitle}  artist:${BeatsService.artist}`,
        "{WEATHER}": WeatherService.weatherData.currentTemp,
        "{ALARMS}": AlarmService.alarms
    }

    // Gemini: https://ai.google.dev/gemini-api/docs/function-calling
    // OpenAI: https://platform.openai.com/docs/guides/function-calling
    property string currentTool: Mem.options.ai.tool ?? "search"
    property var tools: {
        "gemini": {
            "functions": [
                {
                    "functionDeclarations": [
                        {
                            "name": "get_timers",
                            "description": "Get all current timers with their status, duration, and remaining time"
                        },
                        {
                            "name": "add_timer",
                            "description": "Create a new timer with a name and duration",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "name": {
                                        "type": "string",
                                        "description": "Name/description of the timer"
                                    },
                                    "duration": {
                                        "type": "string",
                                        "description": "Duration in format like '25m', '1h30m', '45s', or just '25' for minutes"
                                    }
                                },
                                "required": ["name", "duration"]
                            }
                        },
                        {
                            "name": "start_timer",
                            "description": "Start or resume a timer by its ID",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "timer_id": {
                                        "type": "integer",
                                        "description": "The timer ID from get_timers"
                                    }
                                },
                                "required": ["timer_id"]
                            }
                        },
                        {
                            "name": "pause_timer",
                            "description": "Pause a running timer by its ID",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "timer_id": {
                                        "type": "integer",
                                        "description": "The timer ID from get_timers"
                                    }
                                },
                                "required": ["timer_id"]
                            }
                        },
                        {
                            "name": "reset_timer",
                            "description": "Reset a timer back to its original duration",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "timer_id": {
                                        "type": "integer",
                                        "description": "The timer ID from get_timers"
                                    }
                                },
                                "required": ["timer_id"]
                            }
                        },
                        {
                            "name": "delete_timer",
                            "description": "Remove/delete a timer completely",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "timer_id": {
                                        "type": "integer",
                                        "description": "The timer ID from get_timers"
                                    }
                                },
                                "required": ["timer_id"]
                            }
                        },
                        {
                            "name": "get_tasks",
                            "description": "Get the current to-do list with all tasks and their statuses. Use this to check tasks before modifying them."
                        },
                        {
                            "name": "add_task",
                            "description": "Add a new task to the to-do list",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "content": {
                                        "type": "string",
                                        "description": "The task description"
                                    }
                                },
                                "required": ["content"]
                            }
                        },
                        {
                            "name": "update_task_status",
                            "description": "Update the status of a task. Status values: 0=Not Started, 1=In Progress, 2=Final Touches, 3=Finished",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "index": {
                                        "type": "integer",
                                        "description": "The task index from get_tasks (0-based)"
                                    },
                                    "status": {
                                        "type": "integer",
                                        "description": "New status: 0=todo, 1=in_progress, 2=final_touches, 3=done"
                                    }
                                },
                                "required": ["index", "status"]
                            }
                        },
                        {
                            "name": "delete_task",
                            "description": "Delete a task from the to-do list",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "index": {
                                        "type": "integer",
                                        "description": "The task index from get_tasks (0-based)"
                                    }
                                },
                                "required": ["index"]
                            }
                        },
                        {
                            "name": "search_online_inbrowser",
                            "description": "Open Browser and search for a user request. The query should be valid https url will be used to search.",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "query": {
                                        "type": "string",
                                        "description": "Valid HTTPS URL"
                                    }
                                },
                                "required": ["query"]
                            }
                        },
                        {
                            "name": "edit_task",
                            "description": "Edit the content of a task",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "index": {
                                        "type": "integer",
                                        "description": "The task index from get_tasks (0-based)"
                                    },
                                    "content": {
                                        "type": "string",
                                        "description": "The new task content"
                                    }
                                },
                                "required": ["index", "content"]
                            }
                        },
                        {
                            "name": "switch_to_search_mode",
                            "description": "Search the web"
                        },
                        {
                            "name": "get_shell_config",
                            "description": "Get the desktop shell config file contents"
                        },
                        {
                            "name": "set_shell_config",
                            "description": "Set a field in the desktop graphical shell config file. Must only be used after `get_shell_config`.",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "key": {
                                        "type": "string",
                                        "description": "The key to set, e.g. `bar.borderless`. MUST NOT BE GUESSED, use `get_shell_config` to see what keys are available before setting."
                                    },
                                    "value": {
                                        "type": "string",
                                        "description": "The value to set, e.g. `true`"
                                    }
                                },
                                "required": ["key", "value"]
                            }
                        },
                        {
                            "name": "run_shell_command",
                            "description": "Run a shell command in bash and get its output. Use this only for quick commands that don't require user interaction. For commands that require interaction, ask the user to run manually instead.",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "command": {
                                        "type": "string",
                                        "description": "The bash command to run"
                                    }
                                },
                                "required": ["command"]
                            }
                        },
                    ]
                }
            ],
            "search": [
                {
                    "google_search": {}
                }
            ],
            "none": []
        },
        "openai": {
            "functions": [
                {
                    "type": "function",
                    "function": {
                        "name": "search_online_inbrowser",
                        "description": "Open Browser and search for a user request. The query should be valid https url will be used to search.",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "query": {
                                    "type": "string",
                                    "description": "Valid HTTP URL"
                                }
                            },
                            "required": ["query"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "get_timers",
                        "description": "Get all current timers with their status, duration, and remaining time",
                        "parameters": {
                            "type": "object",
                            "properties": {}
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "add_timer",
                        "description": "Create a new timer with a name and duration",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "name": {
                                    "type": "string",
                                    "description": "Name/description of the timer"
                                },
                                "duration": {
                                    "type": "string",
                                    "description": "Duration in format like '25m', '1h30m', '45s', or just '25' for minutes"
                                }
                            },
                            "required": ["name", "duration"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "start_timer",
                        "description": "Start or resume a timer by its ID",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "timer_id": {
                                    "type": "integer",
                                    "description": "The timer ID from get_timers"
                                }
                            },
                            "required": ["timer_id"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "pause_timer",
                        "description": "Pause a running timer by its ID",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "timer_id": {
                                    "type": "integer",
                                    "description": "The timer ID from get_timers"
                                }
                            },
                            "required": ["timer_id"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "reset_timer",
                        "description": "Reset a timer back to its original duration",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "timer_id": {
                                    "type": "integer",
                                    "description": "The timer ID from get_timers"
                                }
                            },
                            "required": ["timer_id"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "delete_timer",
                        "description": "Remove/delete a timer completely",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "timer_id": {
                                    "type": "integer",
                                    "description": "The timer ID from get_timers"
                                }
                            },
                            "required": ["timer_id"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "get_tasks",
                        "description": "Get the current to-do list with all tasks and their statuses. Use this to check tasks before modifying them.",
                        "parameters": {
                            "type": "object",
                            "properties": {}
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "add_task",
                        "description": "Add a new task to the to-do list",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "content": {
                                    "type": "string",
                                    "description": "The task description"
                                }
                            },
                            "required": ["content"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "update_task_status",
                        "description": "Update the status of a task. Status values: 0=Not Started, 1=In Progress, 2=Final Touches, 3=Finished",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "index": {
                                    "type": "integer",
                                    "description": "The task index from get_tasks (0-based)"
                                },
                                "status": {
                                    "type": "integer",
                                    "description": "New status: 0=todo, 1=in_progress, 2=final_touches, 3=done"
                                }
                            },
                            "required": ["index", "status"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "delete_task",
                        "description": "Delete a task from the to-do list",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "index": {
                                    "type": "integer",
                                    "description": "The task index from get_tasks (0-based)"
                                }
                            },
                            "required": ["index"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "edit_task",
                        "description": "Edit the content of a task",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "index": {
                                    "type": "integer",
                                    "description": "The task index from get_tasks (0-based)"
                                },
                                "content": {
                                    "type": "string",
                                    "description": "The new task content"
                                }
                            },
                            "required": ["index", "content"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "get_shell_config",
                        "description": "Get the desktop shell config file contents",
                        "parameters": {
                            "type": "object",
                            "properties": {}
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "set_shell_config",
                        "description": "Set a field in the desktop graphical shell config file. Must only be used after `get_shell_config`.",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "key": {
                                    "type": "string",
                                    "description": "The key to set, e.g. `bar.borderless`. MUST NOT BE GUESSED, use `get_shell_config` to see what keys are available before setting."
                                },
                                "value": {
                                    "type": "string",
                                    "description": "The value to set, e.g. `true`"
                                }
                            },
                            "required": ["key", "value"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "run_shell_command",
                        "description": "Run a shell command in bash and get its output. Use this only for quick commands that don't require user interaction. For commands that require interaction, ask the user to run manually instead.",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "command": {
                                    "type": "string",
                                    "description": "The bash command to run"
                                }
                            },
                            "required": ["command"]
                        }
                    }
                }
            ],
            "search": [],
            "none": []
        },
        "mistral": {
            "functions": [
                {
                    "type": "function",
                    "function": {
                        "name": "get_shell_config",
                        "description": "Get the desktop shell config file contents",
                        "parameters": {}
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "set_shell_config",
                        "description": "Set a field in the desktop graphical shell config file. Must only be used after `get_shell_config`.",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "key": {
                                    "type": "string",
                                    "description": "The key to set, e.g. `bar.borderless`. MUST NOT BE GUESSED, use `get_shell_config` to see what keys are available before setting."
                                },
                                "value": {
                                    "type": "string",
                                    "description": "The value to set, e.g. `true`"
                                }
                            },
                            "required": ["key", "value"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "run_shell_command",
                        "description": "Run a shell command in bash and get its output. Use this only for quick commands that don't require user interaction. For commands that require interaction, ask the user to run manually instead.",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "command": {
                                    "type": "string",
                                    "description": "The bash command to run"
                                }
                            },
                            "required": ["command"]
                        }
                    }
                },
            ],
            "search": [],
            "none": []
        }
    }
    property list<var> availableTools: Object.keys(root.tools[models[currentModelId]?.api_format])
    property var toolDescriptions: {
        "functions": qsTr("Commands, edit configs, search.\nTakes an extra turn to switch to search mode if that's needed"),
        "search": qsTr("Gives the model search capabilities (immediately)"),
        "none": qsTr("Disable tools")
    }

    // Model properties:
    // - name: Name of the model
    // - icon: Icon name of the model
    // - description: Description of the model
    // - endpoint: Endpoint of the model
    // - model: Model name of the model
    // - requires_key: Whether the model requires an API key
    // - key_id: The identifier of the API key. Use the same identifier for models that can be accessed with the same key.
    // - key_get_link: Link to get an API key
    // - key_get_description: Description of pricing and how to get an API key
    // - api_format: The API format of the model. Can be "openai" or "gemini". Default is "openai".
    // - extraParams: Extra parameters to be passed to the model. This is a JSON object.
    property var models: Mem.options.policies.ai === 2 ? {} : {
        "gemini-2.0-flash": aiModelComponent.createObject(this, {
            "name": "Gemini 2.0 Flash",
            "icon": "google-gemini-symbolic",
            "description": qsTr("Online | Google's model\nFast, can perform searches for up-to-date information"),
            "homepage": "https://aistudio.google.com",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:streamGenerateContent",
            "model": "gemini-2.0-flash",
            "requires_key": true,
            "key_id": "gemini",
            "key_get_link": "https://aistudio.google.com/app/apikey",
            "key_get_description": qsTr("**Pricing**: free. Data used for training.\n\n**Instructions**: Log into Google account, allow AI Studio to create Google Cloud project or whatever it asks, go back and click Get API key"),
            "api_format": "gemini"
        }),
        "gemini-2.5-flash": aiModelComponent.createObject(this, {
            "name": "Gemini 2.5 Flash",
            "icon": "google-gemini-symbolic",
            "description": qsTr("Online | Google's model\nNewer model that's slower than its predecessor but should deliver higher quality answers"),
            "homepage": "https://aistudio.google.com",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent",
            "model": "gemini-2.5-flash",
            "requires_key": true,
            "key_id": "gemini",
            "key_get_link": "https://aistudio.google.com/app/apikey",
            "key_get_description": qsTr("**Pricing**: free. Data used for training.\n\n**Instructions**: Log into Google account, allow AI Studio to create Google Cloud project or whatever it asks, go back and click Get API key"),
            "api_format": "gemini"
        }),
        "gemini-2.5-flash-pro": aiModelComponent.createObject(this, {
            "name": "Gemini 2.5 Pro",
            "icon": "google-gemini-symbolic",
            "description": qsTr("Online | Google's model\nGoogle's state-of-the-art multipurpose model that excels at coding and complex reasoning tasks."),
            "homepage": "https://aistudio.google.com",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:streamGenerateContent",
            "model": "gemini-2.5-pro",
            "requires_key": true,
            "key_id": "gemini",
            "key_get_link": "https://aistudio.google.com/app/apikey",
            "key_get_description": qsTr("**Pricing**: free. Data used for training.\n\n**Instructions**: Log into Google account, allow AI Studio to create Google Cloud project or whatever it asks, go back and click Get API key"),
            "api_format": "gemini"
        }),
        "gemini-2.5-flash-lite": aiModelComponent.createObject(this, {
            "name": "Gemini 2.5 Flash-Lite",
            "icon": "google-gemini-symbolic",
            "description": qsTr("Online | Google's model\nA Gemini 2.5 Flash model optimized for cost-efficiency and high throughput."),
            "homepage": "https://aistudio.google.com",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:streamGenerateContent",
            "model": "gemini-2.5-flash-lite",
            "requires_key": true,
            "key_id": "gemini",
            "key_get_link": "https://aistudio.google.com/app/apikey",
            "key_get_description": qsTr("**Pricing**: free. Data used for training.\n\n**Instructions**: Log into Google account, allow AI Studio to create Google Cloud project or whatever it asks, go back and click Get API key"),
            "api_format": "gemini"
        }),
        "mistral-medium-3": aiModelComponent.createObject(this, {
            "name": "Mistral Medium 3",
            "icon": "mistral-symbolic",
            "description": qsTr("Online | %1's model | Delivers fast, responsive and well-formatted answers. Disadvantages: not very eager to do stuff; might make up unknown function calls").arg("Mistral"),
            "homepage": "https://mistral.ai/news/mistral-medium-3",
            "endpoint": "https://api.mistral.ai/v1/chat/completions",
            "model": "mistral-medium-2505",
            "requires_key": true,
            "key_id": "mistral",
            "key_get_link": "https://console.mistral.ai/api-keys",
            "key_get_description": qsTr("**Instructions**: Log into Mistral account, go to Keys on the sidebar, click Create new key"),
            "api_format": "mistral"
        }),
        "perplexity-sonar-deep-research": aiModelComponent.createObject(this, {
            "name": "Sonar Deep Research",
            "icon": "perplexity-symbolic",
            "description": qsTr("Online | Perplexity's model\nIn-depth analysis and comprehensive reports with exhaustive web research"),
            "homepage": "https://www.perplexity.ai",
            "endpoint": "https://api.perplexity.ai/chat/completions",
            "model": "sonar-deep-research",
            "requires_key": true,
            "key_id": "perplexity",
            "key_get_link": "https://www.perplexity.ai/settings/api",
            "key_get_description": qsTr("**Pricing**: Pay-as-you-go. Pro users get $5/month credit.\n\n**Instructions**: Log into Perplexity account, go to Settings > API, click Generate API Key"),
            "api_format": "openai"
        }),
        "perplexity-sonar": aiModelComponent.createObject(this, {
            "name": "Sonar",
            "icon": "perplexity-symbolic"  // You'll need to add this icon
            ,
            "description": qsTr("Online | Perplexity's model\nFast search model for quick factual queries and current events"),
            "homepage": "https://www.perplexity.ai",
            "endpoint": "https://api.perplexity.ai/chat/completions",
            "model": "sonar",
            "requires_key": true,
            "key_id": "perplexity",
            "key_get_link": "https://www.perplexity.ai/settings/api",
            "key_get_description": qsTr("**Pricing**: Pay-as-you-go. Pro users get $5/month credit.\n\n**Instructions**: Log into Perplexity account, go to Settings > API, click Generate API Key"),
            "api_format": "openai"
        }),
        "perplexity-sonar-pro": aiModelComponent.createObject(this, {
            "name": "Sonar Pro",
            "icon": "perplexity-symbolic",
            "description": qsTr("Online | Perplexity's model\nAdvanced search with enhanced accuracy and detail"),
            "homepage": "https://www.perplexity.ai",
            "endpoint": "https://api.perplexity.ai/chat/completions",
            "model": "sonar-pro",
            "requires_key": true,
            "key_id": "perplexity",
            "key_get_link": "https://www.perplexity.ai/settings/api",
            "key_get_description": qsTr("**Pricing**: Pay-as-you-go. Pro users get $5/month credit.\n\n**Instructions**: Log into Perplexity account, go to Settings > API, click Generate API Key"),
            "api_format": "openai"
        }),
        "perplexity-sonar-reasoning": aiModelComponent.createObject(this, {
            "name": "Sonar Reasoning",
            "icon": "perplexity-symbolic",
            "description": qsTr("Online | Perplexity's model\nExcels at complex multi-step tasks and logical problem-solving"),
            "homepage": "https://www.perplexity.ai",
            "endpoint": "https://api.perplexity.ai/chat/completions",
            "model": "sonar-reasoning",
            "requires_key": true,
            "key_id": "perplexity",
            "key_get_link": "https://www.perplexity.ai/settings/api",
            "key_get_description": qsTr("**Pricing**: Pay-as-you-go. Pro users get $5/month credit.\n\n**Instructions**: Log into Perplexity account, go to Settings > API, click Generate API Key"),
            "api_format": "openai"
        }),
        "perplexity-sonar-deep-research": aiModelComponent.createObject(this, {
            "name": "Sonar Deep Research",
            "icon": "perplexity-symbolic",
            "description": qsTr("Online | Perplexity's model\nIn-depth analysis and comprehensive reports with exhaustive web research"),
            "homepage": "https://www.perplexity.ai",
            "endpoint": "https://api.perplexity.ai/chat/completions",
            "model": "sonar-deep-research",
            "requires_key": true,
            "key_id": "perplexity",
            "key_get_link": "https://www.perplexity.ai/settings/api",
            "key_get_description": qsTr("**Pricing**: Pay-as-you-go. Pro users get $5/month credit.\n\n**Instructions**: Log into Perplexity account, go to Settings > API, click Generate API Key"),
            "api_format": "openai"
        }),
        "github-gpt-5-nano": aiModelComponent.createObject(this, {
            "name": "GPT-5 Nano (GH Models)",
            "icon": "github-symbolic",
            "api_format": "openai",
            "description": qsTr("Online via %1 | %2's model").arg("GitHub Models").arg("OpenAI"),
            "homepage": "https://github.com/marketplace/models",
            "endpoint": "https://models.inference.ai.azure.com/chat/completions",
            "model": "gpt-5-nano",
            "requires_key": true,
            "key_id": "github",
            "key_get_link": "https://github.com/settings/tokens",
            "key_get_description": qsTr("**Pricing**: Free tier available with limited rates. See https://docs.github.com/en/billing/concepts/product-billing/github-models\n\n**Instructions**: Generate a GitHub personal access token with Models permission, then set as API key here\n\n**Note**: To use this you will have to set the temperature parameter to 1")
        }),
        "openrouter-deepseek-r1": aiModelComponent.createObject(this, {
            "name": "DeepSeek R1",
            "icon": "deepseek-symbolic",
            "description": qsTr("Online via %1 | %2's model").arg("OpenRouter").arg("DeepSeek"),
            "homepage": "https://openrouter.ai/deepseek/deepseek-r1:free",
            "endpoint": "https://openrouter.ai/api/v1/chat/completions",
            "model": "deepseek/deepseek-r1:free",
            "requires_key": true,
            "key_id": "openrouter",
            "key_get_link": "https://openrouter.ai/settings/keys",
            "key_get_description": qsTr("**Pricing**: free. Data use policy varies depending on your OpenRouter account settings.\n\n**Instructions**: Log into OpenRouter account, go to Keys on the topright menu, click Create API Key")
        }),
        "openai-gpt-4o-mini": aiModelComponent.createObject(this, {
            "name": "GPT-4o Mini",
            "icon": "openai-symbolic",
            "description": qsTr("Online | OpenAI's model\nFast and cost-efficient for everyday tasks and quick responses."),
            "homepage": "https://openai.com",
            "endpoint": "https://api.openai.com/v1/chat/completions",
            "model": "gpt-4o-mini",
            "requires_key": true,
            "key_id": "openai",
            "key_get_link": "https://platform.openai.com/api-keys",
            "key_get_description": qsTr("**Pricing**: Pay-as-you-go. See https://openai.com/pricing\n\n**Instructions**: Log into OpenAI account, go to API keys, click Create new secret key"),
            "api_format": "openai"
        }),
        "openai-gpt-5": aiModelComponent.createObject(this, {
            "name": "GPT-5",
            "icon": "openai-symbolic",
            "description": qsTr("Online | OpenAI's model\nState-of-the-art for complex reasoning, coding, and multimodal tasks."),
            "homepage": "https://openai.com",
            "endpoint": "https://api.openai.com/v1/chat/completions",
            "model": "gpt-5",
            "requires_key": true,
            "key_id": "openai",
            "key_get_link": "https://platform.openai.com/api-keys",
            "key_get_description": qsTr("**Pricing**: Pay-as-you-go. See https://openai.com/pricing\n\n**Instructions**: Log into OpenAI account, go to API keys, click Create new secret key"),
            "api_format": "openai"
        }),
        "grok-grok-4": aiModelComponent.createObject(this, {
            "name": "Grok 4",
            "icon": "grok-symbolic",
            "description": qsTr("Online | xAI's model\nAdvanced reasoning model built for helpful, truthful responses with a touch of humor."),
            "homepage": "https://grok.x.ai",
            "endpoint": "https://api.x.ai/v1/chat/completions",
            "model": "grok-4",
            "requires_key": true,
            "key_id": "grok",
            "key_get_link": "https://console.x.ai/api-keys",
            "key_get_description": qsTr("**Pricing**: Pay-as-you-go with free tier options. See https://x.ai/pricing\n\n**Instructions**: Sign up at x.ai, log into console, navigate to API keys, and create a new key"),
            "api_format": "openai"
        }),
        "openrouter-grok-4-fast": aiModelComponent.createObject(this, {
            "name": "Grok 4 Fast (Free)",
            "icon": "grok-symbolic",
            "description": qsTr("Online via %1 | xAI's fast multimodal model with free access (limited time)").arg("OpenRouter"),
            "homepage": "https://openrouter.ai/x-ai/grok-4-fast:free",
            "endpoint": "https://openrouter.ai/api/v1/chat/completions",
            "model": "x-ai/grok-4-fast:free",
            "requires_key": true,
            "key_id": "openrouter",
            "key_get_link": "https://openrouter.ai/settings/keys",
            "key_get_description": qsTr("**Pricing**: Free (limited time). Data use policy varies depending on your OpenRouter account settings.\n\n**Instructions**: Log into OpenRouter account, go to Keys on the topright menu, click Create API Key"),
            "api_format": "openai"
        })
    }
    property var modelList: Object.keys(root.models)
    property var currentModelId: Mem.options.ai?.model || modelList[0]

    property var apiStrategies: {
        "openai": openaiApiStrategy.createObject(this),
        "gemini": geminiApiStrategy.createObject(this),
        "mistral": mistralApiStrategy.createObject(this)
    }
    property ApiStrategy currentApiStrategy: apiStrategies[models[currentModelId]?.api_format || "openai"]
    property string requestScriptFilePath: "/tmp/noon/ai/request.sh"
    property string pendingFilePath: ""

    Component.onCompleted: {
        setModel(currentModelId, false, false); // Do necessary setup for model
    }

    function guessModelLogo(model) {
        if (model.includes("llama"))
            return "ollama-symbolic";
        if (model.includes("gemma"))
            return "google-gemini-symbolic";
        if (model.includes("deepseek"))
            return "deepseek-symbolic";
        if (/^phi\d*:/i.test(model))
            return "microsoft-symbolic";
        return "ollama-symbolic";
    }

    function guessModelName(model) {
        const replaced = model.replace(/-/g, ' ').replace(/:/g, ' ');
        let words = replaced.split(' ');
        words[words.length - 1] = words[words.length - 1].replace(/(\d+)b$/, (_, num) => `${num}B`);
        words = words.map(word => {
            return (word.charAt(0).toUpperCase() + word.slice(1));
        });
        if (words[words.length - 1] === "Latest")
            words.pop();
        else
            words[words.length - 1] = `(${words[words.length - 1]})`; // Surround the last word with square brackets
        const result = words.join(' ');
        return result;
    }

    function addModel(modelName, data) {
        root.models[modelName] = aiModelComponent.createObject(this, data);
    }

    Process {
        id: getOllamaModels
        running: true
        command: ["bash", "-c", `${Directories.scriptsDir}/ai/show-installed-ollama-models.sh`.replace(/file:\/\//, "")]
        stdout: SplitParser {
            onRead: data => {
                try {
                    if (data.length === 0)
                        return;
                    const dataJson = JSON.parse(data);
                    root.modelList = [...root.modelList, ...dataJson];
                    dataJson.forEach(model => {
                        const safeModelName = root.safeModelName(model);
                        root.addModel(safeModelName, {
                            "name": guessModelName(model),
                            "icon": guessModelLogo(model),
                            "description": qsTr("Local Ollama model | %1").arg(model),
                            "homepage": `https://ollama.com/library/${model}`,
                            "endpoint": "http://localhost:11434/v1/chat/completions",
                            "model": model,
                            "requires_key": false
                        });
                    });

                    root.modelList = Object.keys(root.models);
                } catch (e) {
                    console.log("Could not fetch Ollama models:", e);
                }
            }
        }
    }

    Process {
        id: getDefaultPrompts
        running: true
        command: ["ls", "-1", Directories.defaultAiPrompts]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0)
                    return;
                root.defaultPrompts = text.split("\n").filter(fileName => fileName.endsWith(".md") || fileName.endsWith(".txt")).map(fileName => `${Directories.defaultAiPrompts}/${fileName}`);
            }
        }
    }

    Process {
        id: getUserPrompts
        running: true
        command: ["ls", "-1", Directories.userAiPrompts]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0)
                    return;
                root.userPrompts = text.split("\n").filter(fileName => fileName.endsWith(".md") || fileName.endsWith(".txt")).map(fileName => `${Directories.userAiPrompts}/${fileName}`);
            }
        }
    }

    Process {
        id: getSavedChats
        running: true
        command: ["ls", "-1", Directories.aiChats]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0)
                    return;
                root.savedChats = text.split("\n").filter(fileName => fileName.endsWith(".json")).map(fileName => `${Directories.aiChats}/${fileName}`);
            }
        }
    }

    FileView {
        id: promptLoader
        watchChanges: false
        onLoadedChanged: {
            if (!promptLoader.loaded)
                return;
            Mem.options.ai.systemPrompt = promptLoader.text();
            root.addMessage(qsTr("Loaded the following system prompt\n\n---\n\n%1").arg(Mem.options.ai.systemPrompt), root.interfaceRole);
        }
    }

    function printPrompt() {
        root.addMessage(qsTr("The current system prompt is\n\n---\n\n%1").arg(Mem.options.ai.systemPrompt), root.interfaceRole);
    }

    function loadPrompt(filePath) {
        promptLoader.path = ""; // Unload
        promptLoader.path = filePath; // Load
        promptLoader.reload();
    }

    function addMessage(message, role) {
        if (message.length === 0)
            return;
        const aiMessage = aiMessageComponent.createObject(root, {
            "role": role,
            "content": message,
            "rawContent": message,
            "thinking": false,
            "done": true
        });
        const id = idForMessage(aiMessage);
        root.messageIDs = [...root.messageIDs, id];
        root.messageByID[id] = aiMessage;
    }

    function removeMessage(index) {
        if (index < 0 || index >= messageIDs.length)
            return;
        const id = root.messageIDs[index];
        root.messageIDs.splice(index, 1);
        root.messageIDs = [...root.messageIDs];
        delete root.messageByID[id];
    }

    function addApiKeyAdvice(model) {
        root.addMessage(qsTr('To set an API key, pass it with the %4 command\n\nTo view the key, pass "get" with the command<br/>\n\n### For %1:\n\n**Link**: %2\n\n%3').arg(model.name).arg(model.key_get_link).arg(model.key_get_description ?? qsTr("<i>No further instruction provided</i>")).arg("/key"), Ai.interfaceRole);
    }

    function getModel() {
        return models[currentModelId];
    }

    function setModel(modelId, feedback = true, setConfigState = true) {
        if (!modelId)
            modelId = "";
        modelId = modelId.toLowerCase();
        if (modelList.indexOf(modelId) !== -1) {
            const model = models[modelId];
            // Fetch API keys if needed
            if (model?.requires_key)
                KeyringStorage.fetchKeyringData();
            // See if policy prevents online models
            if (Mem.options.policies.ai === 2 && !model.endpoint.includes("localhost")) {
                root.addMessage(qsTr("Online models disallowed\n\nControlled by `policies.ai` config option"), root.interfaceRole);
                return;
            }
            if (setConfigState)
                Mem.options.ai.model = modelId;
            if (feedback)
                root.addMessage(qsTr("Model set to %1").arg(model.name), root.interfaceRole);
            if (model.requires_key) {
                // If key not there show advice
                if (root.apiKeysLoaded && (!root.apiKeys[model.key_id] || root.apiKeys[model.key_id].length === 0)) {
                    root.addApiKeyAdvice(model);
                }
            }
        } else {
            if (feedback)
                root.addMessage(qsTr("Invalid model. Supported: \n```\n") + modelList.join("\n```\n```\n"), Ai.interfaceRole) + "\n```";
        }
    }

    function setTool(tool) {
        if (!root.tools[models[currentModelId]?.api_format] || !(tool in root.tools[models[currentModelId]?.api_format])) {
            root.addMessage(qsTr("Invalid tool. Supported tools:\n- %1").arg(root.availableTools.join("\n- ")), root.interfaceRole);
            return false;
        }
        Mem.options.ai.tool = tool;
        return true;
    }

    function getTemperature() {
        return root.temperature;
    }

    function setTemperature(value) {
        if (value == NaN || value < 0 || value > 2) {
            root.addMessage(qsTr("Temperature must be between 0 and 2"), Ai.interfaceRole);
            return;
        }
        Mem.options.ai.temperature = value;
        root.temperature = value;
        root.addMessage(qsTr("Temperature set to %1").arg(value), Ai.interfaceRole);
    }

    function setApiKey(key) {
        const model = models[currentModelId];
        if (!model.requires_key) {
            root.addMessage(qsTr("%1 does not require an API key").arg(model.name), Ai.interfaceRole);
            return;
        }
        if (!key || key.length === 0) {
            const model = models[currentModelId];
            root.addApiKeyAdvice(model);
            return;
        }
        KeyringStorage.setNestedField(["apiKeys", model.key_id], key.trim());
        root.addMessage(qsTr("API key set for %1").arg(model.name), Ai.interfaceRole);
    }

    function printApiKey() {
        const model = models[currentModelId];
        if (model.requires_key) {
            const key = root.apiKeys[model.key_id];
            if (key) {
                root.addMessage(qsTr("API key:\n\n```txt\n%1\n```").arg(key), Ai.interfaceRole);
            } else {
                root.addMessage(qsTr("No API key set for %1").arg(model.name), Ai.interfaceRole);
            }
        } else {
            root.addMessage(qsTr("%1 does not require an API key").arg(model.name), Ai.interfaceRole);
        }
    }

    function printTemperature() {
        root.addMessage(qsTr("Temperature: %1").arg(root.temperature), Ai.interfaceRole);
    }

    function clearMessages() {
        root.messageIDs = [];
        root.messageByID = ({});
        root.tokenCount.input = -1;
        root.tokenCount.output = -1;
        root.tokenCount.total = -1;
    }

    FileView {
        id: requesterScriptFile
    }

    Process {
        id: requester
        property list<string> baseCommand: ["bash"]
        property AiMessageData message
        property ApiStrategy currentStrategy

        function markDone() {
            requester.message.done = true;
            if (root.postResponseHook) {
                root.postResponseHook();
                root.postResponseHook = null; // Reset hook after use
            }
            root.saveChat("lastSession");
            root.responseFinished();
        }

        function makeRequest() {
            const model = models[currentModelId];
            requester.currentStrategy = root.currentApiStrategy;
            requester.currentStrategy.reset(); // Reset strategy state

            /* Put API key in environment variable */
            if (model.requires_key)
                requester.environment[`${root.apiKeyEnvVarName}`] = root.apiKeys ? (root.apiKeys[model.key_id] ?? "") : "";

            /* Build endpoint, request data */
            const endpoint = root.currentApiStrategy.buildEndpoint(model);
            const messageArray = root.messageIDs.map(id => root.messageByID[id]);
            const filteredMessageArray = messageArray.filter(message => message.role !== Ai.interfaceRole);
            const data = root.currentApiStrategy.buildRequestData(model, filteredMessageArray, root.systemPrompt, root.temperature, root.tools[model.api_format][root.currentTool], root.pendingFilePath);
            // console.log("[Ai] Request data: ", JSON.stringify(data, null, 2));

            let requestHeaders = {
                "Content-Type": "application/json"
            };

            /* Create local message object */
            requester.message = root.aiMessageComponent.createObject(root, {
                "role": "assistant",
                "model": currentModelId,
                "content": "",
                "rawContent": "",
                "thinking": true,
                "done": false
            });
            const id = idForMessage(requester.message);
            root.messageIDs = [...root.messageIDs, id];
            root.messageByID[id] = requester.message;

            /* Build header string for curl */
            let headerString = Object.entries(requestHeaders).filter(([k, v]) => v && v.length > 0).map(([k, v]) => `-H '${k}: ${v}'`).join(' ');

            // console.log("Request headers: ", JSON.stringify(requestHeaders));
            // console.log("Header string: ", headerString);

            /* Get authorization header from strategy */
            const authHeader = requester.currentStrategy.buildAuthorizationHeader(root.apiKeyEnvVarName);

            /* Script shebang */
            const scriptShebang = "#!/usr/bin/env bash\n";

            /* Create extra setup when there's an attached file */
            let scriptFileSetupContent = "";
            if (root.pendingFilePath && root.pendingFilePath.length > 0) {
                requester.message.localFilePath = root.pendingFilePath;
                scriptFileSetupContent = requester.currentStrategy.buildScriptFileSetup(root.pendingFilePath);
                root.pendingFilePath = "";
            }

            /* Create command string */
            let scriptRequestContent = "";
            scriptRequestContent += `curl --no-buffer "${endpoint}"` + ` ${headerString}` + (authHeader ? ` ${authHeader}` : "") + ` --data '${CF.StringUtils.shellSingleQuoteEscape(JSON.stringify(data))}'` + "\n";

            /* Send the request */
            const scriptContent = requester.currentStrategy.finalizeScriptContent(scriptShebang + scriptFileSetupContent + scriptRequestContent);
            const shellScriptPath = CF.FileUtils.trimFileProtocol(root.requestScriptFilePath);
            requesterScriptFile.path = Qt.resolvedUrl(shellScriptPath);
            requesterScriptFile.setText(scriptContent);
            requester.command = baseCommand.concat([shellScriptPath]);
            requester.running = true;
        }

        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0)
                    return;
                if (requester.message.thinking)
                    requester.message.thinking = false;
                // console.log("[Ai] Raw response line: ", data);

                // Handle response line
                try {
                    const result = requester.currentStrategy.parseResponseLine(data, requester.message);
                    // console.log("[Ai] Parsed response result: ", JSON.stringify(result, null, 2));

                    if (result.functionCall) {
                        requester.message.functionCall = result.functionCall;
                        root.handleFunctionCall(result.functionCall.name, result.functionCall.args, requester.message);
                    }
                    if (result.tokenUsage) {
                        root.tokenCount.input = result.tokenUsage.input;
                        root.tokenCount.output = result.tokenUsage.output;
                        root.tokenCount.total = result.tokenUsage.total;
                    }
                    if (result.finished) {
                        requester.markDone();
                    }
                } catch (e) {
                    console.log("[AI] Could not parse response: ", e);
                    requester.message.rawContent += data;
                    requester.message.content += data;
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            const result = requester.currentStrategy.onRequestFinished(requester.message);

            if (result.finished) {
                requester.markDone();
            } else if (!requester.message.done) {
                requester.markDone();
            }

            // Handle error responses
            if (requester.message.content.includes("API key not valid")) {
                root.addApiKeyAdvice(models[requester.message.model]);
            }
        }
    }

    function sendUserMessage(message) {
        if (message.length === 0)
            return;
        root.addMessage(message, "user");
        requester.makeRequest();
    }

    function attachFile(filePath: string) {
        root.pendingFilePath = CF.FileUtils.trimFileProtocol(filePath);
    }

    function createFunctionOutputMessage(name, output, includeOutputInChat = true) {
        return aiMessageComponent.createObject(root, {
            "role": "user",
            "content": `[[ Output of ${name} ]]${includeOutputInChat ? ("\n\n<think>\n" + output + "\n</think>") : ""}`,
            "rawContent": `[[ Output of ${name} ]]${includeOutputInChat ? ("\n\n<think>\n" + output + "\n</think>") : ""}`,
            "functionName": name,
            "functionResponse": output,
            "thinking": false,
            "done": true
            // "visibleToUser": false,
        });
    }

    function addFunctionOutputMessage(name, output) {
        const aiMessage = createFunctionOutputMessage(name, output);
        const id = idForMessage(aiMessage);
        root.messageIDs = [...root.messageIDs, id];
        root.messageByID[id] = aiMessage;
    }

    function rejectCommand(message: AiMessageData) {
        if (!message.functionPending)
            return;
        message.functionPending = false; // User decided, no more "thinking"
        addFunctionOutputMessage(message.functionName, qsTr("Command rejected by user"));
    }

    function approveCommand(message: AiMessageData) {
        if (!message.functionPending)
            return;
        message.functionPending = false; // User decided, no more "thinking"

        const responseMessage = createFunctionOutputMessage(message.functionName, "", false);
        const id = idForMessage(responseMessage);
        root.messageIDs = [...root.messageIDs, id];
        root.messageByID[id] = responseMessage;

        commandExecutionProc.message = responseMessage;
        commandExecutionProc.baseMessageContent = responseMessage.content;
        commandExecutionProc.shellCommand = message.functionCall.args.command;
        commandExecutionProc.running = true; // Start the command execution
    }

    Process {
        id: commandExecutionProc
        property string shellCommand: ""
        property AiMessageData message
        property string baseMessageContent: ""
        command: ["bash", "-c", shellCommand]
        stdout: SplitParser {
            onRead: output => {
                commandExecutionProc.message.functionResponse += output + "\n\n";
                const updatedContent = commandExecutionProc.baseMessageContent + `\n\n<think>\n<tt>${commandExecutionProc.message.functionResponse}</tt>\n</think>`;
                commandExecutionProc.message.rawContent = updatedContent;
                commandExecutionProc.message.content = updatedContent;
            }
        }
        onExited: (exitCode, exitStatus) => {
            commandExecutionProc.message.functionResponse += `[[ Command exited with code ${exitCode} (${exitStatus}) ]]\n`;
            requester.makeRequest(); // Continue
        }
    }

    function handleFunctionCall(name, args: var, message: AiMessageData) {
        if (name === "switch_to_search_mode") {
            const modelId = root.currentModelId;
            root.currentTool = "search";
            root.postResponseHook = () => {
                root.currentTool = "functions";
            };
            addFunctionOutputMessage(name, qsTr("Switched to search mode. Continue with the user's request."));
            requester.makeRequest();
        } else if (name === "get_shell_config") {
            const configJson = CF.ObjectUtils.toPlainObject(Config);
            addFunctionOutputMessage(name, JSON.stringify(configJson));
            requester.makeRequest();
        } else if (name === "set_shell_config") {
            if (!args.key || !args.value) {
                addFunctionOutputMessage(name, qsTr("Invalid arguments. Must provide `key` and `value`."));
                return;
            }
            const key = args.key;
            const value = args.value;
            Mem.options.setNestedValue(key, value);
        } else if (name === "run_shell_command") {
            if (!args.command || args.command.length === 0) {
                addFunctionOutputMessage(name, qsTr("Invalid arguments. Must provide `command`."));
                return;
            }
            const contentToAppend = `\n\n**Command execution request**\n\n\`\`\`command\n${args.command}\n\`\`\``;
            message.rawContent += contentToAppend;
            message.content += contentToAppend;
            message.functionPending = true; // Use thinking to indicate the command is waiting for approval
        } else if (name === "get_tasks") {
            addFunctionOutputMessage(name, formatTasks());
            requester.makeRequest();
        } else if (name === "add_task") {
            if (!args.content || args.content.trim().length === 0) {
                addFunctionOutputMessage(name, qsTr("Invalid arguments. Must provide non-empty `content`."));
                requester.makeRequest();
                return;
            }
            TodoService.addTask(args.content.trim());
            addFunctionOutputMessage(name, qsTr("Task added: %1").arg(args.content));
            requester.makeRequest();
        } else if (name === "update_task_status") {
            if (args.index === undefined || args.status === undefined) {
                addFunctionOutputMessage(name, qsTr("Invalid arguments. Must provide `index` and `status`."));
                requester.makeRequest();
                return;
            }
            if (args.index < 0 || args.index >= TodoService.list.length) {
                addFunctionOutputMessage(name, qsTr("Invalid task index: %1. Valid range: 0-%2").arg(args.index).arg(TodoService.list.length - 1));
                requester.makeRequest();
                return;
            }
            if (args.status < TodoService.status_todo || args.status > TodoService.status_done) {
                addFunctionOutputMessage(name, qsTr("Invalid status: %1. Valid range: 0-3").arg(args.status));
                requester.makeRequest();
                return;
            }
            TodoService.setStatus(args.index, args.status);
            addFunctionOutputMessage(name, qsTr("Task %1 status updated to %2").arg(args.index).arg(TodoService.getStatusName(args.status)));
            requester.makeRequest();
        } else if (name === "delete_task") {
            if (args.index === undefined) {
                addFunctionOutputMessage(name, qsTr("Invalid arguments. Must provide `index`."));
                requester.makeRequest();
                return;
            }
            if (args.index < 0 || args.index >= TodoService.list.length) {
                addFunctionOutputMessage(name, qsTr("Invalid task index: %1. Valid range: 0-%2").arg(args.index).arg(TodoService.list.length - 1));
                requester.makeRequest();
                return;
            }
            const taskContent = TodoService.getItemContent(args.index);
            TodoService.deleteItem(args.index);
            addFunctionOutputMessage(name, qsTr("Task deleted: %1").arg(taskContent));
            requester.makeRequest();
        } else if (name === "edit_task") {
            if (args.index === undefined || !args.content) {
                addFunctionOutputMessage(name, qsTr("Invalid arguments. Must provide `index` and `content`."));
                requester.makeRequest();
                return;
            }
            if (args.index < 0 || args.index >= TodoService.list.length) {
                addFunctionOutputMessage(name, qsTr("Invalid task index: %1. Valid range: 0-%2").arg(args.index).arg(TodoService.list.length - 1));
                requester.makeRequest();
                return;
            }
            const success = TodoService.editItem(args.index, args.content);
            if (success) {
                addFunctionOutputMessage(name, qsTr("Task %1 updated to: %2").arg(args.index).arg(args.content));
            } else {
                addFunctionOutputMessage(name, qsTr("Failed to update task %1").arg(args.index));
            }
            requester.makeRequest();
        } else if (name === "get_timers") {
            addFunctionOutputMessage(name, formatTimers());
            requester.makeRequest();
        } else if (name === "add_timer") {
            if (!args.name || !args.duration) {
                addFunctionOutputMessage(name, qsTr("Invalid arguments. Must provide 'name' and 'duration'."));
                requester.makeRequest();
                return;
            }
            const durationSeconds = TimerService.parseTimeString(args.duration);
            if (durationSeconds <= 0) {
                addFunctionOutputMessage(name, qsTr("Invalid duration format. Use formats like '25m', '1h30m', or '45'."));
                requester.makeRequest();
                return;
            }
            const timerId = TimerService.addTimer(args.name, durationSeconds, null);
            addFunctionOutputMessage(name, qsTr("Timer created with ID %1: %2 (%3)").arg(timerId).arg(args.name).arg(TimerService.formatTime(durationSeconds)));
            requester.makeRequest();
        } else if (name === "start_timer") {
            if (args.timer_id === undefined) {
                addFunctionOutputMessage(name, qsTr("Invalid arguments. Must provide 'timer_id'."));
                requester.makeRequest();
                return;
            }
            const timer = TimerService.uiTimers.find(t => t.id === args.timer_id);
            if (!timer) {
                addFunctionOutputMessage(name, qsTr("Timer with ID %1 not found").arg(args.timer_id));
                requester.makeRequest();
                return;
            }
            TimerService.startTimer(args.timer_id);
            addFunctionOutputMessage(name, qsTr("Timer %1 started: %2").arg(args.timer_id).arg(timer.name));
            requester.makeRequest();
        } else if (name === "pause_timer") {
            if (args.timer_id === undefined) {
                addFunctionOutputMessage(name, qsTr("Invalid arguments. Must provide 'timer_id'."));
                requester.makeRequest();
                return;
            }
            const timer = TimerService.uiTimers.find(t => t.id === args.timer_id);
            if (!timer) {
                addFunctionOutputMessage(name, qsTr("Timer with ID %1 not found").arg(args.timer_id));
                requester.makeRequest();
                return;
            }
            TimerService.pauseTimer(args.timer_id);
            addFunctionOutputMessage(name, qsTr("Timer %1 paused: %2").arg(args.timer_id).arg(timer.name));
            requester.makeRequest();
        } else if (name === "reset_timer") {
            if (args.timer_id === undefined) {
                addFunctionOutputMessage(name, qsTr("Invalid arguments. Must provide 'timer_id'."));
                requester.makeRequest();
                return;
            }
            const timer = TimerService.uiTimers.find(t => t.id === args.timer_id);
            if (!timer) {
                addFunctionOutputMessage(name, qsTr("Timer with ID %1 not found").arg(args.timer_id));
                requester.makeRequest();
                return;
            }
            TimerService.resetTimer(args.timer_id);
            addFunctionOutputMessage(name, qsTr("Timer %1 reset: %2").arg(args.timer_id).arg(timer.name));
            requester.makeRequest();
        } else if (name === "delete_timer") {
            if (args.timer_id === undefined) {
                addFunctionOutputMessage(name, qsTr("Invalid arguments. Must provide 'timer_id'."));
                requester.makeRequest();
                return;
            }
            const timer = TimerService.uiTimers.find(t => t.id === args.timer_id);
            if (!timer) {
                addFunctionOutputMessage(name, qsTr("Timer with ID %1 not found").arg(args.timer_id));
                requester.makeRequest();
                return;
            }
            const timerName = timer.name;
            TimerService.removeTimer(args.timer_id);
            addFunctionOutputMessage(name, qsTr("Timer %1 deleted: %2").arg(args.timer_id).arg(timerName));
            requester.makeRequest();
        } else if (name === "search_online_inbrowser") {
            if (!args.query || args.query.trim().length === 0) {
                addFunctionOutputMessage(name, qsTr("Invalid arguments. Must provide non-empty 'query'."));
                requester.makeRequest();
                return;
            }
            Noon.execDetached(["xdg-open", args.query]);
        } else
            root.addMessage(qsTr("Unknown function call: %1").arg(name), "assistant");
    }

    function chatToJson() {
        return root.messageIDs.map(id => {
            const message = root.messageByID[id];
            return ({
                    "role": message.role,
                    "rawContent": message.rawContent,
                    "fileMimeType": message.fileMimeType,
                    "fileUri": message.fileUri,
                    "localFilePath": message.localFilePath,
                    "model": message.model,
                    "thinking": false,
                    "done": true,
                    "annotations": message.annotations,
                    "annotationSources": message.annotationSources,
                    "functionName": message.functionName,
                    "functionCall": message.functionCall,
                    "functionResponse": message.functionResponse,
                    "visibleToUser": message.visibleToUser
                });
        });
    }

    FileView {
        id: chatSaveFile
        property string chatName: ""
        path: chatName.length > 0 ? `${Directories.aiChats}/${chatName}.json` : ""
        blockLoading: true // Prevent race conditions
    }
    /*
    * Helper Function that formats the current timers in timers service
    */
    function formatTimers() {
        if (!TimerService.uiTimers || TimerService.uiTimers.length === 0) {
            return "No timers currently";
        }

        let output = "Current timers:\n\n";

        TimerService.uiTimers.forEach(timer => {
            const status = timer.isRunning ? "🟢 Running" : timer.isPaused ? "⏸️ Paused" : "⏹️ Stopped";

            const remaining = TimerService.formatTime(timer.remainingTime);
            const total = TimerService.formatTime(timer.originalDuration);
            const progress = TimerService.getProgressPercentage(timer.id).toFixed(1);

            output += `ID: ${timer.id}\n`;
            output += `Name: ${timer.name}\n`;
            output += `Status: ${status}\n`;
            output += `Time: ${remaining} / ${total} (${progress}% complete)\n`;
            output += `Icon: ${timer.icon}\n`;
            output += `\n`;
        });

        return output;
    }

    /*
    * Helper Function that formats the current tasks in todo/ist service
    */
    function formatTasks() {
        if (!TodoService.list || TodoService.list.length === 0) {
            return "No tasks currently";
        }

        let output = "Current tasks:\n\n";

        for (let status = TodoService.status_todo; status <= TodoService.status_done; status++) {
            const tasks = TodoService.getTasksByStatus(status);
            if (tasks.length > 0) {
                output += `## ${TodoService.getStatusName(status)} (${tasks.length})\n`;
                tasks.forEach((task, idx) => {
                    const globalIndex = TodoService.list.indexOf(task);
                    output += `${globalIndex}. ${task.content}\n`;
                });
                output += "\n";
            }
        }

        return output;
    }
    /**
     * Saves chat to a JSON list of message objects.
     * @param chatName name of the chat
     */
    function saveChat(chatName) {
        chatSaveFile.chatName = chatName.trim();
        const saveContent = JSON.stringify(root.chatToJson());
        chatSaveFile.setText(saveContent);
        getSavedChats.running = true;
    }

    /**
     * Loads chat from a JSON list of message objects.
     * @param chatName name of the chat
     */
    function loadChat(chatName) {
        try {
            chatSaveFile.chatName = chatName.trim();
            chatSaveFile.reload();
            const saveContent = chatSaveFile.text();
            // console.log(saveContent)
            const saveData = JSON.parse(saveContent);
            root.clearMessages();
            root.messageIDs = saveData.map((_, i) => {
                return i;
            });
            // console.log(JSON.stringify(messageIDs))
            for (let i = 0; i < saveData.length; i++) {
                const message = saveData[i];
                root.messageByID[i] = root.aiMessageComponent.createObject(root, {
                    "role": message.role,
                    "rawContent": message.rawContent,
                    "content": message.rawContent,
                    "fileMimeType": message.fileMimeType,
                    "fileUri": message.fileUri,
                    "localFilePath": message.localFilePath,
                    "model": message.model,
                    "thinking": message.thinking,
                    "done": message.done,
                    "annotations": message.annotations,
                    "annotationSources": message.annotationSources,
                    "functionName": message.functionName,
                    "functionCall": message.functionCall,
                    "functionResponse": message.functionResponse,
                    "visibleToUser": message.visibleToUser
                });
            }
        } catch (e) {
            console.log("[AI] Could not load chat: ", e);
        } finally {
            getSavedChats.running = true;
        }
    }
}
