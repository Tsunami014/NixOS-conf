{ config, lib, pkgs, master-pkgs, ... }:
let
  rule = effect: action: { inherit action effect; resource = "*"; };
  ruleOn = effect: action: resource: { inherit action effect resource; };

  baseConfig = {
    "$schema" = "https://opencode.ai/config.json";
    agents = {
      chat = {
        description = "Just have a chat, nothing too complex";
        mode = "primary";
        system = "You are a concise assistant.";
        permissions =
          [ (rule "deny" "*") ]
          ++ map (rule "allow") [ "read" "edit" "glob" "grep" ]
          ++ [ (rule "ask" "shell") ]
          ++ [
            (ruleOn "allow" "edit" "*AGENTS.md")
            (ruleOn "allow" "read" "*AGENTS.md")
          ];
      };
      agentic = {
        description = "That's so agentic";
        mode = "primary";
        system = ''You are a concise coding orchestrator.
Delegate with the `subagent` tool: one subagent per independent piece of work.
A subagent reloads the whole prompt, so do not create subagents with small tasks - instead, give subagents small goals.
Brief each subagent with the goal, exact file paths and what "done" means. Tell it to use the code tool in small chunks and use tools unless a script would be more efficient.
Also if subagents shouldn't need to respond with much information tell them not to, for example if they are only editing files they do not need to explain that they did after. Also ensure to tell them to keep their response concise while containing all relevant information
Subagents only have the context you give them, so ensure you give them as much context as they will need, and ensure you clearly define the scope so they do not research/perform actions that are unhelpful.
For 3+ steps, write a todo list before launching and tick items off as reports arrive.
Verify (build, tests or diff) before finishing.
Durable project facts (e.g. build/test commands, conventions, important files) go in AGENTS.md as a short note. No progress logs.
If unsure, investigate first and only then ask.
If you ever need to search folders for something, ensure you match broadly first - things may be where you do not expect.
'';
        permissions =
          [ (rule "deny" "*") ]
          ++ map (rule "allow") [ "subagent" "todo*" "question" ];
      };
    };
    default_agent = "chat";
    provider.ollama = {
      npm = "@ai-sdk/openai-compatible";
      name = "Ollama";
      options.baseURL = "http://localhost:11434/v1";
      timeout = false; # Large contexts can take a very long time
    };
  };

  baseConfigFile = pkgs.writeText "opencode-base.json" (builtins.toJSON baseConfig);

  opencodeConfigDir  = "${config.xdg.configHome}/opencode";
  opencodeConfigPath = "${opencodeConfigDir}/opencode.json";

  syncScript = pkgs.writeShellScript "opencode-sync-ollama-models" ''
    set -euo pipefail
    mkdir -p "${opencodeConfigDir}"

    if tags_json=$(${pkgs.curl}/bin/curl -sf --max-time 3 http://localhost:11434/api/tags); then
      models_json=$(echo "$tags_json" | ${pkgs.jq}/bin/jq '
        { provider: { ollama: { models: (
            (.models // []) | map({ (.name): { name: .name } }) | add // {}
          ) } } }
      ')
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "${baseConfigFile}" <(echo "$models_json") \
        > "${opencodeConfigPath}.tmp"
      mv "${opencodeConfigPath}.tmp" "${opencodeConfigPath}"
    else
      echo "opencode: ollama not reachable at localhost:11434, keeping existing model list" >&2
      # first-run fallback so the file exists even if ollama was never up
      [ -f "${opencodeConfigPath}" ] || cp "${baseConfigFile}" "${opencodeConfigPath}"
    fi
  '';
in
{
  home.activation.opencodeModels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${syncScript}
  '';

  home.packages = [
    (pkgs.writeShellScriptBin "opencode-refresh-models" "exec ${syncScript}")
    master-pkgs.opencode
  ];
}
